# 3C509B-nestor
8086 Driver for 3COM Etherlink III 3C509B cards

The 3COM 3C509B card is known to work with computers with a 16-bit ISA bus, but the reason for this is not that the card physically requires it, but because the software uses assembly opcodes found in the 286 processor. That means the original IBM PC and XT (which have an 8-bit ISA bus) cannot use the card. Or rather, they couldn't.

[Nestor](http://www.vcfed.org/forum/member.php?12204-nestor) a.k.a. [Distwave](http://ibmps1.wordpress.com/) of [VCFed.org](http://www.vcfed.org/) took the time in 2012 to [replace all the 286 specific assembly instructions with generic 8086 code](http://www.vcfed.org/forum/showthread.php?30537-Feeling-lucky-is-the-3c509B-compatible-with-8088-using-NE1000-drivers&p=224266#post224266). Nestor used the packet driver source code from [crynwr.com](http://web.archive.org/web/*/http://www.crynwr.com/drivers/), which was released under the GNU GPL license.

This repository is meant to be a secondary place to hold the source code and to log the changes Nestor made. (Look at the history for the file 3c509.asm). Hopefully, having this in version control will also allow other changes people have made (such as hacks  to get it to work on the V20 CPU) to be incorporated in a clean way. 

Nota bene: while this driver works with any 3C509**B** card (the B is important), at least one of those cards, the 3C509B-**TP** card requires software configuration before it can be used in a PC/XT machine. Please see below for details.

## Installation
Download [3c509.com](https://github.com/hackerb9/3C509B-nestor/raw/3c509.com) to get Ethernet working. 

To get on the Internet, you'll also need software that handles TCP/IP such as [mTCP](https://www.brutman.com/mTCP/). 

## Basic Usage
Run the COM file with the software interrupt number: **3C509.COM** _<packet_int_no>_

The readme suggests using 0x7e, like so:
```dos
A:\> 3C509.COM 0x7e
```

## Advanced Usage

According to the source code comments, _<packet_int_no>_'s range is 0x60 to 0x66, 0x68 to 0x6f, and 0x7b to 0x7e.
Why the gaps? 0x67 is the EMS interrupt, 0x70 through 0x77 are used by the second 8259, and 0x7a is used by NetWare's IPX.

If you run the COM file with no parameters, you'll see this message:
```dos
usage: 3c509 [options] <packet_int_no> [id_port]
-i -- Force driver to report itself as IEEE 802.3 instead of Ethernet II.
-d -- Delayed initialization.  Used for diskless booting
-n -- NetWare conversion.  Converts 802.3 packets into 8137 packets
-w -- Windows hack, obsoleted by winpkt
-p -- Promiscuous mode disable
-m -- Micronetics MSM compatibility
-u -- Uninstall
```

## What cards does this work with?

| Card ID                      | Connector Type        | Cable                                    | Works? |
| ---------------------------- | --------------------- | ---------------------------------------- | :----: |
| 3C509B<br/>(3C509B-Coax)     | BNC<br/>AUI           | 10base2<br/>Thick coax                   | Yes    |   
| 3C509B-C<br/>(3C509B-COMBO)  | RJ-45<br/>BNC<br/>AUI | 10baseT<br/>10base2<br/>Thick coax       | Yes    | 
| 3C509B-TP                    | RJ-45<br/>BNC         | 10baseT<br/>10base2                      | With configuration |
| 3C509B-TPO                   | RJ-45                 | 10baseT                                  | With configuration |

## Software configuration on a 286

The 3C509B-**TP** and perhaps **TPO** may require software configuration in a 286 machine before they can be used in a PC or XT. If no NIC is detected by the 3c509.com driver, follow these steps:

1. Put the network card in a 286 machine.
1. Run 3Com's [3C5X9CFG.EXE](https://github.com/hackerb9/3C509B-nestor/3c5x9x/raw/3C5X9CFG.EXE) (found in [3C5X9X.ZIP](3c5x9x/3C5X9X.zip)).
   1. Disable PNP
   1. Set the IRQ to 2 (or another free IRQ, see table below)
   1. Optimize for DOS
   1. No modem installed
   1. Change the Base Address to 0x320, if you have an XT-IDE at 0x300
   1. Change port transciever (RJ45, BNC, AUI), if you wish
1. Save settings to EEPROM.
1. Move the card back to your IBM PC / XT.
1. Running `3c509.com 0x7e` should now work. 


## IRQs
| IRQ | PC/XT Use    | Used by default? | Notes   |
| --- | ------------ | ---------------- | ------- |
| 0   | System Timer | yes | Not wired to ISA bus |
| 1   | Keyboard     | yes | Not wired to ISA bus |
| 2   | Available    |     |
| 3   | COM2 / COM4  |     |
| 4   | COM1 / COM3  | yes |
| 5   | Hard Disk<br/>Soundcard    |     |
| 6   | Floppy       | yes |
| 7   | Parallel     | yes | Many people remove LPT1 to free this IRQ |

## Future work

The 3COM configuration program runs on an 8086 machine but does not detect the NIC, so you'll need a 286 or better machine temporarily. It is unclear why this happens since 3COM clearly states that the 3C509B works in 8-bit busses. 

### 3C5X9CFG /PNPRST; 3C5X9CFG CONFIGURE /PNP:DISABLED

According to archive.org's cache of 3com.com's [FAQ](http://web.archive.org/web/20060314235414/http://support.3com.com/infodeli/inotes/techtran/2406_5ea.htm), when the "No Etherlink III Adapter Found" error is seen, one should run the following and reboot:
```
3C5X9CFG /PNPRST 
3C5X9CFG CONFIGURE /PNP:DISABLED
```
This has not yet been tested on an 8086/8088 machine, but may fix the problem without a 286.

Here is the commentary from INSTALL.TXT from EtherDisk V4.3b

> Installing an EtherLink III ISA adapter (3C509B) in certain computers
 may result in neither the diagnostic and configuration program nor the
 driver being able find the adapter. The problem is your computer's BIOS is
 issuing a series of I/O instructions that causes the 3C509B to think it's
 going to be activated as a Plug 'N Play (PnP) device.  Unfortunately, the
 adapter waits for the PnP series to complete and ignores the "classic" or
 "legacy" method for discovering an EtherLink III ISA adapter.  The fix for
 this problem is very simple; follow the steps below:
> 1. Boot a minimal DOS setup, making sure that no EtherLink III drivers are loaded.
> 2. Put this EtherDisk in the diskette drive and type A: at the DOS prompt.
> 3.  Enter PNPDSABL [_which is just a BAT file that executes the two 
      [3C5X9CFG](3c5x9x/3C5X9CFG.EXE) commands above_] 
      at the DOS prompt.  The configuration and diagnostic
      program will execute twice.  The first time it executes, the configuration
      and diagnostic program "kicks" the EtherLink III out of its PnP wait.
      During the second execution, it disables Plug 'n Play. The final message
      displayed will be:
        "The 3C5X9 adapter, adapter number 1, was successfully configured"
> 4. Finally, remove the EtherDisk from the diskette drive, and turn the
      computer power off, then on. 



### Or, could it be the IRQ?
It may be because the default IRQ is 10, which is an illegal IRQ for the 8-bit PC/XT ISA bus. However, one user reported that the configuration program does not work even after changing the IRQ, so it seems unlikely.

### Is it fixable?
This may be fixable by hacking 3C5X9CFG.EXE to branch around the NIC detection code. Or perhaps a new 8086 configuration utility can be written by looking at the [Linux 3C509 configuration code](https://github.com/torvalds/linux/blob/master/drivers/net/ethernet/3com/3c509.c).
