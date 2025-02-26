# Cynthion Development VM

This is a virtual machine intended for [Cynthion](https://cynthion.readthedocs.io/en/latest/) development. [Debian Bookworm (v12)](https://debian.org)  is being used as the guest operating system (OS). 

## Prerequisites

In order to build the virtual machine image, you will need:

- [Hashicorp Packer](https://www.packer.io/)* >= v1.12.0
- [Qemu](https://qemu.org) >= v9.2.0
- [Go Task](https://taskfile.dev/) >= v3.41.0

## Quickstart

The `taskfile.yml` features the `build` task to launch packer and have the image build and provisioned with [cloud-init](https://cloud-init.io/). 
Just run 

```bash
task build 
```

### Access 

The build process artificially introduces a waiting time due to some unresolved oddities with `cloud-init` (See below). After the build has successfully executed, we need to start the VM by running 

```bash
start task
```

The vm will now boot. Once the boot is complete, we can access the vm via ssh. (Make sure your packet filter allows local connections)

```bash
ssh -p 2222 user@localhost
```

There is a user defined called `user` with the password set to `user`. Please be reminded, that this setup is **meant for local development only! Do not use this configuration in a production system, that can be accessed publicly.** 


## Packages

The virtual machine comes with a set of preinstalled software to make development a breeze. Following software is configured to be installed:


| Tool                                                                                          | Description                                                                                                 |
|:----------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------------------------------------|
| [Rust](https://rust-lang.org)                                                                 | The Rust systems programming language                                                                       |
| [Neovim](https://github.com/neovim/neovim/releases/download/v0.10.4/)                         | A versatile editor                                                                                          |
| [Astrovim](https://github.com/AstroNvim/template)                                             | An extension to neovim with lang server support                                                             |
| [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2025-02-10/) | the Project Trellis ECP5 tools consisting of the yosys synthesis suite and the NextPNR place-and-route tool |
| [Cynthion Development Kit](https://github.com/greatscottgadgets/cynthion)                     | The cynthion project including moondancer to develop cynthion firmware in Rust.                             |
| [Python >= v3](https://python.org)                                                            | A script-kiddie language not to be taken seriously, but is required to run some tools                       |

There are some other useful tools. Look at [assets/user-data](./assets/user-data) to see what is being installed.

## Connecting Cynthion

Depending on your system, you need to figure out the 16 bit product id and vendor id, and bind this usb device to qemu. ( See [Taskfile.yml](./taskfile.yml) fo details. For now it should just work, but in case cynthion cannot be found check both values for correctness. The vendor and product id must be the same across all systems. ) 

Connect your Cynthion device to the `control` port and excute following command to find your device


<details>
<summary>on MacOS</summary>

<p>

```bash
system_profile SPUSBDataType
```

This should give you a list of all the USB devices on your system. A similar list should be printed out.

```bash
USB Analyzer:

    Product ID: 0x615b
    Vendor ID: 0x1d50
    Version: 1.05
    Serial Number: </redacted>
    Speed: Up to 480 Mb/s
    Manufacturer: Cynthion Project
    Location ID: </redacted>
    Current Available (mA): 500
    Current Required (mA): 500
    Extra Operating Current (mA): 0
```
</p>
</details>

<details>
<summary>on Linux</summary>

<p>

Run the command "lsusb." If you don't have the tool installed, check your distribution's documentation to see how to install it.  

```bash
sudo lsusb
```
This should give you a list of all the USB devices on your system. A similar list should be printed out.

```bash
Bus 002 Device 003: ID 1d50:615b OpenMoko, Inc. USB Analyzer
Bus 003 Device 001: ID xxxx:xxxx Linux Foundation 3.0 root hub
Bus 002 Device 002: ID xxxx:xxxx Adomax Technology Co., Ltd QEMU Tablet
Bus 002 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 001 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
```
</p>
</details>

Note the `product id` and the `vendor_id` and start qemu with the usb device attached. A possible configuration under linux may look like this

```bash
qemu-system-x86_64 -usb -device usb-host,vendorid=0x1d50,productid=0x615b
```

### Detecting Cynthion

After the guest VM is built successfully, we can start the machine and log in with the default user name (user) and password (user). You can change this to your liking. Once we have logged in, we can create a Python virtual environment and activate it by entering the following command:

```bash
python3 -m venv venv
source venv/bin/activate
```
We can now install the Cynthion tool. 


```bash
pip install cynthion
```

We need to set up cynthion in order to use it by typing the following command:

```bash
cynthion setup
```

This will download and activate the required udev rules in /etc/udev/rules.d. 
_note:_ At the time of writing, the udev rules won't work directly in Debian, but must be modified. 

Change the content of `/etc/udev/rules.d/54-cynthion-rules` to:

```udev
SUBSYSTEM=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="615b", SYMLINK+="cynthion-%k", TAG+="uaccess", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="615c", SYMLINK+="cynthion-apollo-%k", TAG+="uaccess", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="1209", ATTR{idProduct}=="000a", SYMLINK+="cynthion-test-%k", TAG+="uaccess", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="1209", ATTR{idProduct}=="000e", SYMLINK+="cynthion-example-%k", TAG+="uaccess", MODE="0666"
```

reload the rules and activate them

```bash
sudo udevadm control --reload
sudo udevadm trigger
```

Now we can check for cynthion to be available:

```
cynthion info
```

This would show us a summary of the connected device similar to this:

```
Cynthion version: 0.1.8
Apollo version: 1.1.1
Python version: 3.11.2 (main, Nov 30 2024, 21:22:50) [GCC 12.2.0]

Found Apollo stub interface!
	Bitstream: USB Analyzer (Cynthion Project)
	Vendor ID: 1d50
	Product ID: 615b
	bcdDevice: 0104
	Bitstream serial number: 263f1cdf30c460de

For additional device information use the --force-offline option.
```

And we are done!

## Quirks

As mentioned above, [cloud-init](https://cloud-init.io/) is being used as a provisioning system. The [user script] (./assets/user-data) makes only small changes to the user environment for convenience. However, the provisioning process seems to be interrupted, even though a lock is being maintained to wait for cloud-init to finish. Future versions may fix the current hack to artificially wait a longer time.

## References

- [Cynthion Development Website](https://cynthion.readthedocs.io/en/latest/getting_started.html)
- [Cynthion Device at GreatScott Gadgets](https://greatscottgadgets.com/cynthion/)

## License

Please note that no rights are granted to use this setup at this time. By using this setup, you agree that I cannot be held responsible for its use.

_note:_ **Please note that this is not an official Great Scott Gadgets product. There is no affiliation with Great Scott Gadgets or its developers.**