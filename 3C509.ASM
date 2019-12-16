version	equ	6
;History:1,1
;Fri Mar 08 14:48:42 2002 Merge in Peter Tattum's 3c509b changes.
;Mon Jan 22 15:09:36 1996 we were rejecting frames with dribble set and accepting other errored frames.

        .8086

;  Copyright, 1988-1992, Russell Nelson, Crynwr Software

;   This program is free software; you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, version 1.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program; if not, write to the Free Software
;   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA

	include	defs.asm

code	segment	word public
	assume	cs:code, ds:code

;----------------------------------------------------------------------------;
;                                                                            ;
;       This source file is the property of 3Com Corporation and may not be  ;
;       copied or distributed in any isomorphic form without an appropriate  ;
;       prior licensing arrangement with 3Com Corporation.                   ;
;                                                                            ;
;       Copyright (c) 1988 3Com Corporation                                  ;
;                                                                            ;
;------ Equates -------------------------------------------------------------;
;
; Command code masks
;
CMD_CMDMASK         equ 0F800h                  ; command bits
CMD_ARGMASK         equ 007FFh                  ; argument bits
;
; Command codes, word form
;
CMD_GLOBALRESET     equ 00000b shl 11           ; global reset
CMD_SELECTWINDOW    equ 00001B shl 11           ; select register window
CMD_STARTINTXCVR    equ 00010b shl 11           ; start internal transciver
CMD_RXDISABLE       equ 00011b shl 11           ; rx disable
CMD_RXENABLE        equ 00100b shl 11           ; rx enable
CMD_RXRESET         equ 00101b shl 11           ; rx reset
CMD_RXDISCARD       equ 01000b shl 11           ; rx discard top packet
CMD_TXENABLE        equ 01001b shl 11           ; tx enable
CMD_TXDISABLE       equ 01010b shl 11           ; tx disable
CMD_TXRESET         equ 01011b shl 11           ; tx reset
CMD_REQUESTINT      equ 01100b shl 11           ; request interrupt
CMD_ACKNOWLEDGE     equ 01101b shl 11           ; acknowledge interrupt
CMD_SETINTMASK      equ 01110b shl 11           ; set interrupt mask
CMD_SETRZMASK       equ 01111b shl 11           ; set read zero mask
CMD_SETRXFILTER     equ 10000b shl 11           ; set rx filter
CMD_SETRXEARLY      equ 10001b shl 11           ; set rx early threshold
CMD_SETTXAVAILABLE  equ 10010b shl 11           ; set tx available threshold
CMD_SETTXSTART      equ 10011b shl 11           ; set tx start threshold
CMD_STATSENABLE     equ 10101b shl 11           ; statistics enable
CMD_STATSDISABLE    equ 10110b shl 11           ; statistics disable
CMD_STOPINTXCVR     equ 10111b shl 11           ; start internal transciver
;
; Command codes, hibyte form (commands without operands only)
;
CMDH_STARTINTXCVR   equ CMD_STARTINTXCVR shr 8
CMDH_RXDISABLE      equ CMD_RXDISABLE shr 8
CMDH_RXENABLE       equ CMD_RXENABLE shr 8
CMDH_RXDISCARD      equ CMD_RXDISCARD shr 8
CMDH_TXENABLE       equ CMD_TXENABLE shr 8
CMDH_TXDISABLE      equ CMD_TXDISABLE shr 8
CMDH_REQUESTINT     equ CMD_REQUESTINT shr 8
CMDH_STATSENABLE    equ CMD_STATSENABLE shr 8
CMDH_STATSDISABLE   equ CMD_STATSDISABLE shr 8
CMDH_STOPINTXCVR    equ CMD_STOPINTXCVR shr 8
;
; Status register bits (INT for interrupt sources, ST for the rest)
;
INT_LATCH           equ 00001h                  ; interrupt latch
INT_ADAPTERFAIL     equ 00002h                  ; adapter failure
INT_TXCOMPLETE      equ 00004h                  ; tx complete
INT_TXAVAILABLE     equ 00008h                  ; tx available
INT_RXCOMPLETE      equ 00010h                  ; rx complete
INT_RXEARLY         equ 00020h                  ; rx early
INT_REQUESTED       equ 00040h                  ; interrupt requested
INT_UPDATESTATS     equ 00080h                  ; update statistics
ST_FAILED           equ 00800h                  ; command failed
ST_BUSY             equ 01000h                  ; command busy
ST_WINDOW           equ 0E000h                  ; window bits (13-15)

STH_FAILED          equ ST_FAILED shr 8
STH_BUSY            equ ST_BUSY shr 8
STH_WINDOW          equ ST_WINDOW shr 8

;
; RxStatus register bits
;
RXS_INCOMPLETE      equ 8000h                   ; not completely received
RXS_ERROR           equ 4000h                   ; error in packet
RXS_LENGTH          equ 07FFh                   ; bytes in RxFIFO
RXS_ERRTYPE         equ 3800h                   ; Rx error type, bit 13-11
RXS_OVERRUN         equ 0000h                   ; overrun error
RXS_OVERSIZE        equ 0800h                   ; oversize packet error
RXS_DRIBBLE         equ 1000h                   ; dribble bit (not an error)
RXS_RUNT            equ 1800h                   ; runt packet error
RXS_CRC             equ 2800h                   ; CRC error
RXS_FRAMING         equ 2000h                   ; framing error

RXSH_INCOMPLETE     equ RXS_INCOMPLETE shr 8
RXSH_ERROR          equ RXS_ERROR shr 8
RXSH_ERRTYPE        equ RXS_ERRTYPE shr 8
RXSH_OVERRUN        equ RXS_OVERRUN shr 8
RXSH_DRIBBLE        equ RXS_DRIBBLE shr 8
RXSH_CRC            equ RXS_CRC shr 8
RXSH_RUNT           equ RXS_RUNT shr 8
RXSH_OVERSIZE       equ RXS_OVERSIZE shr 8
RXSH_FRAMING        equ RXS_FRAMING shr 8
;
; TxStatus register bits
;
TXS_COMPLETE        equ 80h                     ; tx completed
TXS_INTREQUESTED    equ 40h                     ; interrupt on successfull tx
TXS_ERRTYPE         equ 38h                     ; error bits
TXS_JABBERERROR     equ 20h                     ; jabber error
TXS_UNDERRUN        equ 10h                     ; tx underrun error
TXS_MAXCOLLISIONS   equ 08h                     ; max collisions error
TXS_STATUSOVERFLOW  equ 04h                     ; TX status stack is full
;
; Window Numbers
;
WNO_SETUP           equ 0                       ; setup/configuration
WNO_OPERATING       equ 1                       ; operating set
WNO_STATIONADDRESS  equ 2                       ; station address setup/read
WNO_FIFO            equ 3                       ; FIFO management
WNO_DIAGNOSTICS     equ 4                       ; diagnostics
WNO_READABLE        equ 5                       ; registers set by commands
WNO_STATISTICS      equ 6                       ; statistics
;
; Port offsets, Window 1 (WNO_OPERATING)
;
PORT_CmdStatus      equ 0Eh                     ; command/status
PORT_TxFree         equ 0Ch                     ; free transmit bytes
PORT_TxStatus       equ 0Bh                     ; transmit status (byte)
PORT_Timer          equ 0Ah                     ; latency timer (byte)
PORT_RxStatus       equ 08h                     ; receive status
PORT_RxFIFO         equ 00h                     ; RxFIFO read
PORT_TxFIFO         equ 00h                     ; TxFIFO write
;
; Port offsets, Window 0 (WNO_SETUP)
;
PORT_EEData         equ 0Ch                     ; EEProm data register
PORT_EECmd          equ 0Ah                     ; EEProm command register
PORT_CfgResource    equ 08h                     ; resource configuration
PORT_CfgAddress     equ 06h                     ; address configuration
PORT_CfgControl     equ 04h                     ; configuration control
PORT_ProductID      equ 02h                     ; product id (EISA)
PORT_Manufacturer   equ 00h                     ; Manufacturer code (EISA)
;
; Port offsets, Window 2 (WNO_STATIONADDRESS)
;
PORT_SA0_1          equ 00h                     ; station address bytes 0,1
PORT_SA2_3          equ 02h                     ; station address bytes 2,3
PORT_SA4_5          equ 04h                     ; station address bytes 4,5
;
; Port offsets, Window 3 (WNO_FIFO)
;
PORT_ALT_TxFree     equ 0Ch                     ; free transmit bytes (dup)
PORT_RxFree         equ 0Ah                     ; free receive bytes
;
; Port offsets, Window 4 (WNO_DIAGNOSTICS)
;
PORT_MediaStatus    equ 0Ah                     ; media type/status
PORT_SlingshotStatus equ 08h                    ; Slingshot status
PORT_NetDiagnostic  equ 06h                     ; net diagnostic
PORT_FIFODiagnostic equ 04h                     ; FIFO diagnostic
PORT_HostDiagnostic equ 02h                     ; host diagnostic
PORT_TxDiagnostic   equ 00h                     ; tx diagnostic
;
; Port offsets, Window 5 (WNO_READABLE)
;
PORT_RZMask         equ 0Ch                     ; read zero mask
PORT_IntMask        equ 0Ah                     ; interrupt mask
PORT_RxFilter       equ 08h                     ; receive filter
PORT_RxEarly        equ 06h                     ; rx early threshold
PORT_TxAvailable    equ 02h                     ; tx available threshold
PORT_TxStart        equ 00h                     ; tx start threshold
;
; Port offsets, Window 6 (WNO_STATISTICS)
;
PORT_TXBYTES        equ 0Ch                     ; tx bytes ok
PORT_RXBYTES        equ 0Ah                     ; rx bytes ok
PORT_TXDEFER        equ 08h                     ; tx frames deferred (byte)
PORT_RXFRAMES       equ 07h                     ; rx frames ok (byte)
PORT_TXFRAMES       equ 06h                     ; tx frames ok (byte)
PORT_RXDISCARDED    equ 05h                     ; rx frames discarded (byte)
PORT_TXLATE         equ 04h                     ; tx frames late coll. (byte)
PORT_TXSINGLE       equ 03h                     ; tx frames one coll. (byte)
PORT_TXMULTIPLE     equ 02h                     ; tx frames mult. coll. (byte)
PORT_TXNOCD         equ 01h                     ; tx frames no CDheartbt (byte)
PORT_TXCARRIERLOST  equ 00h                     ; tx frames carrier lost (byte)
;
; Various command arguments
;
INT_ALLDISABLED         equ 00000000000b            ; all interrupts disabled
INT_ALLENABLED          equ 00011111110b            ; all interrupts enabled

FILTER_INDIVIDUAL       equ 0001b                   ; individual address
FILTER_MULTICAST        equ 0010b                   ; multicast/group addresses
FILTER_BROADCAST        equ 0100b                   ; broadcast address
FILTER_PROMISCUOUS      equ 1000b                   ; promiscuous mode

RXEARLY_DISABLED        equ 2032                    ; RxEarly to disable

TXAVAIL_DISABLED        equ 2040                    ; TxAvailable to disable
TXAVAIL_MIN             equ 4

TXSTART_DISABLED        equ 2040                    ; TxStart to disable
TXSTART_MIN             equ 0
TXSTART_MAX             equ TXSTART_DISABLED

RXLENGTH_MAX            equ 1792                    ; maximum rxlength
;
; Transmit Preamble
;
PREAMBLESIZE            equ 4                       ; transmit preamble size
TXP_INTONSUCCESS        equ 8000h                   ; interrupt on successful tx
;
; Bits in various diagnostics registers
;
MEDIA_TP                equ 8000h                   ; TP transciever
MEDIA_BNC               equ 4000h                   ; Thinnet transciever
MEDIA_INTENDEC          equ 2000h                   ; internal encoder/decoder
MEDIA_SQE               equ 1000h                   ; SQE present
MEDIA_LBEAT             equ 0800h                   ; link beat ok (TP)
MEDIA_POLARITY          equ 0400h                   ; polarity (TP)
MEDIA_JABBER            equ 0200h                   ; jabber (TP)
MEDIA_UNSQUELCH         equ 0100h                   ; unsquelch (TP)
MEDIA_LBEATENABLE       equ 0080h                   ; link beat enable (TP)
MEDIA_JABBERENABLE      equ 0040h                   ; jabber enable (TP)
MEDIA_CRS               equ 0020h                   ; carrier sense
MEDIA_COLLISION         equ 0010h                   ; collision
MEDIA_SQEENABLE         equ 0008h                   ; enable SQE statistics

NETD_EXTLOOPBACK        equ 8000h                   ; TP external loopback
NETD_ENDECLOOPBACK      equ 4000h                   ; ENDEC loopback
NETD_CORELOOPBACK       equ 2000h                   ; ethernet core loopback
NETD_FIFOLOOPBACK       equ 1000h                   ; FIFO loopback
NETD_TXENABLED          equ 0800h                   ; tx enabled
NETD_RXENABLED          equ 0400h                   ; rx enabled
NETD_TXTRANSMITTING     equ 0200h                   ; tx transmitting
NETD_TXRESETREQD        equ 0100h                   ; tx reset required

FIFOD_RXRECEIVING       equ 8000h                   ; rx receiveing
FIFOD_RXUNDERRUN        equ 2000h                   ; rx underrun
FIFOD_RXSTATUSOVER      equ 1000h                   ; rx status overrun
FIFOD_RXOVERRUN         equ 0800h                   ; rx overrun
FIFOD_TXOVERRUN         equ 0400h                   ; tx overrun
FIFOD_BISTRESULTS       equ 00FFh                   ; BIST results (mask)

SLING_TXUNDERRUN        equ 2000h                   ; Slingshot TxUnderrun bit
;
; board identification codes, byte swapped in Rev 0
;
EISA_MANUFACTURER_ID    equ 06D50h                  ; EISA manufacturer code
ISA_PRODUCT_ID          equ 09050h                  ; Product ID for ISA board
PRODUCT_ID_MASK         equ 0F0FFh                  ; Mask off revision nibble
;
; EEProm access
;
EE_BUSY                     equ 8000h                   ; EEProm busy bit in EECmd
EE_TCOM_NODE_ADDR_WORD0     equ 00h
EE_TCOM_NODE_ADDR_WORD1     equ 01h
EE_TCOM_NODE_ADDR_WORD2     equ 02h
EE_VULCAN_PROD_ID           equ 03h
EE_MANUFACTURING_DATA       equ 04h
EE_SERIAL_NUMBER_WORD0      equ 05h
EE_SERIAL_NUMBER_WORD1      equ 06h
EE_MANUFACTURER_CODE        equ 07h
EE_ADDR_CONFIGURATION       equ 08h
EE_RESOURCE_CONFIGURATION   equ 09h
EE_OEM_NODE_ADDR_WORD0      equ 0Ah
EE_OEM_NODE_ADDR_WORD1      equ 0Bh
EE_OEM_NODE_ADDR_WORD2      equ 0Ch
EE_SOFTWARE_CONFIG_INFO     equ 0Dh
EE_CWORD                    equ 0Eh
;
; contention logic
;
READ_EEPROM             equ 080h
ID_GLOBAL_RESET		equ 0C0h
SET_TAG_REGISTER        equ 0D0h
TEST_TAG_REGISTER       equ 0D8h
ACTIVATE_AND_SET_IO     equ 0E0h
ACTIVATE_VULCAN         equ 0FFh
;
; Resource Configuration Register bits
;
RCONFIG_IRQ             equ 0F000h
;
; Address Configuration Register bits
;
ACONFIG_XCVR            equ 0C000h
ACONFIG_IOBASE          equ 0001Fh

IOBASE_EISA             equ 0001Fh

TP_XCVR                 equ 00000h
BNC_XCVR                equ 0C000h
AUI_XCVR                equ 04000h

MIN_IO_BASE_ADDR        equ 200h
MAX_IO_BASE_ADDR        equ 3F0h
REGISTER_SET_SIZE       equ 10h
;
; Software Configuration Register bits
;
SW_OPTIMIZE             equ 0030h
SW_MAXCLI               equ 3F00h
SW_LINKBEAT             equ 4000h
;
; Possibilities for SW_OPTIMIZE
;
OPTIMIZE_DOS_CLIENT     equ 0010h
OPTIMIZE_WINDOWS_CLIENT equ 0020h
OPTIMIZE_SERVER         equ 0030h
;
; Configuration Control Register bits
;
ENABLE_ADAPTER          equ 01h

setwin	macro	win
	setport	PORT_CmdStatus
	mov	ax,CMD_SELECTWINDOW+win
	out	dx,ax
	endm

	extrn	is_eisa: byte		;=0 if ISA, =1 if EISA
	extrn	is_186: byte		;=0 if 808[68], =1 if 80[1234]86.
	extrn	is_386: byte		;=0 if 80[12]8[68], =1 if 80[34]86.

	public	int_no, io_addr
int_no	db	0,0,0,0			;must be four bytes long for get_number.
io_addr	dw	0,0			;must be four bytes long for get_number.

	public	driver_class, driver_type, driver_name, driver_function, parameter_list
driver_class	db	BLUEBOOK,IEEE8023,0	;null terminated list of classes.
driver_type	db	94
driver_name	db	'3c509',0	;name of the driver.
driver_function	db	2
parameter_list	label	byte
	db	1	;major rev of packet driver specification
	db	9	;minor rev of packet driver specification
	db	14	;length of parameter list
	db	EADDR_LEN	;length of MAC-layer address
	dw	GIANT	;MTU, including MAC headers
	dw	MAX_MULTICAST * EADDR_LEN	;buffer size of multicast addrs
	dw	0	;(# of back-to-back MTU rcvs) - 1
	dw	0	;(# of successive xmits) - 1
int_num	dw	0	;Interrupt # to hook for post-EOI
			;processing, 0 == none,

	public	rcv_modes
rcv_modes	dw	7		;number of receive modes in our table.
		dw	0               ;There is no mode zero
		dw	rcv_mode_1
		dw	rcv_mode_2
		dw	rcv_mode_3
		dw	0		;haven't set up perfect filtering yet.
		dw	rcv_mode_5
		dw	rcv_mode_6

	include	timeout.asm

	public bad_command_intercept
bad_command_intercept:
;called with ah=command, unknown to the skeleton.
;exit with nc if okay, cy, dh=error if not.
	mov	dh,BAD_COMMAND
	stc
	ret

	public	as_send_pkt
; The Asynchronous Transmit Packet routine.
; Enter with es:di -> i/o control block, ds:si -> packet, cx = packet length,
;   interrupts possibly enabled.
; Exit with nc if ok, or else cy if error, dh set to error number.
;   es:di and interrupt enable flag preserved on exit.
as_send_pkt:
	ret

	public	drop_pkt
; Drop a packet from the queue.
; Enter with es:di -> iocb.
drop_pkt:
	assume	ds:nothing
	ret

	public	xmit
; Process a transmit interrupt with the least possible latency to achieve
;   back-to-back packet transmissions.
; May only use ax and dx.
xmit:
	assume	ds:nothing
	ret

tx_reset:
        push    ax
        push    dx
        loadport
        setport PORT_CmdStatus
        pushf
        cli
	mov	ax,CMD_TXRESET
	out	dx,ax
tx_reset_1:
	in	ax,dx			;wait for the command to finish.
	test	ax,ST_BUSY
	jne	tx_reset_1
        popf

	mov	ax,CMD_TXENABLE		;yes, re-enable the transmitter.
	out	dx,ax
        pop     dx
        pop     ax
        ret

	public	send_pkt
send_pkt:
;enter with es:di->upcall routine, (0:0) if no upcall is desired.
;  (only if the high-performance bit is set in driver_function)
;enter with ds:si -> packet, cx = packet length.
;if we're a high-performance driver, es:di -> upcall.
;exit with nc if ok, or else cy if error, dh set to error number.
	assume	ds:nothing
	cmp	cx,GIANT		; Is this packet too large?
	ja	send_pkt_toobig

	loadport
	setport	PORT_TxStatus		;get the previous transmit status.
	in	al,dx
	setport	PORT_CmdStatus
	test	al,TXS_UNDERRUN or TXS_JABBERERROR	;do we need to reset transmitter?
	je	send_pkt_0
        call    tx_reset
send_pkt_0:
;        test    al,TXS_COMPLETE
;        je send_pkt_0_1
;        out     dx,al
;send_pkt_0_1:

	test	al,TXS_ERRTYPE		;any errors?
	je	send_pkt_3		;no.
	call	count_out_err		;yes, count it.
	mov	ax,CMD_TXENABLE		;yes, re-enable the transmitter.
	out	dx,ax
send_pkt_3:

	mov	bx,cx			;adjust for the size of the preamble,
	add	bx,4 + 3		;and round BX up to dword boundary.
	and	bx,not 3

	setport	PORT_TxFree		;wait for enough bytes in transmit buffer.
	mov	ax,18
	call	set_timeout
send_pkt_1:
	in	ax,dx
	cmp	ax,bx
	jae	send_pkt_2
	call	do_timeout
	jne	send_pkt_1
        call    tx_reset
	mov	dh,CANT_SEND		;timed out, can't send.
	stc
	ret
send_pkt_toobig:
	mov	dh,NO_SPACE
	stc
	ret
send_pkt_2:
	sub	bx,4			;reduce by the size of the preamble.

	setport	PORT_TxFIFO
	mov	ax,cx			;output the count
	out	dx,ax			;   (no interrupt requested)
	out	dx,ax			;output the second reserved word.
	mov	cx,bx			;output the rest of the packet.

;	 cmp	 is_386,0		 ;can we output dwords?
;	 jne	 send_pkt_7		 ;yes.
	shr	cx,1			;output 16 bits at a time.
;	 rep	 outsw

;start 8086 code
send_8086:
	lodsw
	out	dx,ax
	loop send_8086
;end 8086 code

        jmp     short send_pkt_6
;send_pkt_7:
;        .386
;        shr     cx,2                    ;already rounded up.
;        rep     outsd                   ;output 32 bits at a time.
;        .286
send_pkt_6:

	clc
	ret


	public	set_address
set_address:
;enter with ds:si -> Ethernet address, CX = length of address.
;exit with nc if okay, or cy, dh=error if any errors.
	assume	ds:nothing
	cmp	cx,EADDR_LEN		;ensure that their address is okay.
	je	set_address_4
	mov	dh,BAD_ADDRESS
	stc
	jmp	short set_address_done
set_address_4:

	loadport
	setwin	WNO_STATIONADDRESS
	setport	PORT_SA0_1
set_address_1:
	lodsb
	out	dx,al
	inc	dx
	loop	set_address_1
set_address_okay:
	mov	cx,EADDR_LEN		;return their address length.
	clc
set_address_done:
	push	cs
	pop	ds
	assume	ds:code
	loadport
	setwin	WNO_OPERATING
	ret


;skip past the following two bytes while destroying BX.
skip2	macro
	db	0bbh			;opcode of "mov bx,0000"
	endm

rcv_mode_1:
	mov	al,0			;receive nothing
	skip2
rcv_mode_2:
	mov	al,1			;receive individual address
	skip2
rcv_mode_3:
	mov	al,5			;receive individual address+broadcast
	skip2
rcv_mode_5:
	mov	al,3			;receive individual address+group addr(multicast)
	skip2
rcv_mode_6:
	mov	al,8			;receive all packets.
	mov	ah,CMD_SETRXFILTER shr 8	;set receive filter
	loadport
	setport	PORT_CmdStatus
	out	dx,ax
	ret


	public	set_multicast_list
set_multicast_list:
;enter with ds:si ->list of multicast addresses, ax = number of addresses,
;  cx = number of bytes.
;return nc if we set all of them, or cy,dh=error if we didn't.
	mov	dh,NO_MULTICAST
	stc
	ret


	public	terminate
terminate:
	loadport
	setport	PORT_CmdStatus
	mov	ax,CMD_GLOBALRESET
	out	dx,ax
	ret


	public	reset_interface
reset_interface:
;reset the interface.
	assume	ds:code
	ret


;decide if we know this packet's type.
;enter with es:di -> packet type, dl = packet class.
;exit with nc if we know it, cy if not.
	extrn	recv_locate: near

;do the first upcall, get a pointer to the packet.
;enter with cx = packet length.
;exit with cx = packet length, es:di -> buffer for the packet.
	extrn	recv_found: near

;called when we want to determine what to do with a received packet.
;enter with cx = packet length, es:di -> packet type, dl = packet class.
	extrn	recv_find: near

;called after we have copied the packet into the buffer.
;enter with ds:si ->the packet, cx = length of the packet.
	extrn	recv_copy: near

;call this routine to schedule a subroutine that gets run after the
;recv_isr.  This is done by stuffing routine's address in place
;of the recv_isr iret's address.  This routine should push the flags when it
;is entered, and should jump to recv_exiting_exit to leave.
;enter with ax = address of routine to run.
	extrn	schedule_exiting: near

;recv_exiting jumps here to exit, after pushing the flags.
	extrn	recv_exiting_exit: near

	extrn	count_in_err: near
	extrn	count_out_err: near

ether_buff	db	EADDR_LEN  dup(?)
		db	EADDR_LEN  dup(?)
ether_type	db	8 dup(?)
ETHER_BUFF_LEN	equ	$ - ether_buff
.erre	(ETHER_BUFF_LEN and 3) eq 0	;must be an even # of dwords.

early_bytes	dw	0		;the early byte gets the worm.

read_header:
;enter with dx -> PORT_RxFIFO
;exit with es:di -> packet type.

	mov	ax,ds
	mov	es,ax
	mov	di,offset ether_buff
	mov	cx,ETHER_BUFF_LEN/4
repinsd:
	shl	cx,1			;*** this gets changed into "rep insd"
;	 rep	 insw			 ;***	"nop" on a 386 or 486.

;start 8086 code
l_rep:
	in	ax,dx
	stosw
	loop l_rep
;end 8086 code

	mov	di,offset ether_type

	mov	dl, BLUEBOOK		;assume bluebook Ethernet.
	mov	ax, es:[di]
	xchg	ah, al
	cmp 	ax, 1500
	ja	read_header_1
	inc	di			;set di to 802.2 header
	inc	di
	mov	dl, IEEE8023
read_header_1:
	ret


	public	recv
recv:
;called from the recv isr.  All registers have been saved, ds=cs,
;our interrupt has been acknowledged, and our interrupts have been
;masked at the interrupt controller.
	assume	ds:code
recv_another:
	loadport
	setport	PORT_CmdStatus
	in	ax,dx			;did we get a packet?
	or	ax,CMD_ACKNOWLEDGE
	out	dx,ax
	setport	PORT_RxStatus
	test	al,INT_RXCOMPLETE
	jne	recv_complete
	test	al,INT_RXEARLY		;are we getting it early?
	jne	recv_early
	jmp	recv_exit			;no.
recv_early:
	in	ax,dx			;get the amount we can read.
	and	ax,RXS_LENGTH
	cmp	ax,ETHER_BUFF_LEN	;do we have enough to read early?
	jb	recv_early_1		;no, give up.

	mov	early_bytes,ETHER_BUFF_LEN

	setport	PORT_RxFIFO
	call	read_header
	call	recv_locate		;see if this is a type we want.
	jnc	recv_early_1		;it is, just exit.
	jmp	recv_discard		;it isn't.

recv_early_1:
	jmp	recv_another

;yes, this is dead code.  It's only in here to ensure that the setport macro
;has the right value.
	setport	PORT_RxStatus
recv_complete:
	in	ax,dx			;get the size.
	test	ax,RXS_ERROR		;any errors?
	je	recv_complete_2		;no, it's fine.

	and	ax,RXS_ERRTYPE		;get just the error type bits.
	cmp	ax,RXS_DRIBBLE		;dribble is just a warning.
	je	recv_complete_1		;if only dribble is set, that's okay.

recv_err:
	call	count_in_err
	jmp	recv_discard

recv_complete_1:
	in	ax,dx			;get the size again.
recv_complete_2:
;Put it on the receive queue
	and	ax,RXS_LENGTH
	mov	cx,ax

	cmp	early_bytes,0		;did we read the header in already?
	jne	recv_complete_3		;yes, we've already got it.

	cmp	cx,RUNT			;check legal packet size
	jb	recv_err
	cmp	cx,GIANT
	ja	recv_err

	push	cx
	setport	PORT_RxFIFO
	call	read_header
	pop	cx

	push	cx
	call	recv_find
	pop	cx
	jmp	short	recv_complete_4

recv_complete_3:
	add	cx,early_bytes		;add in the early bytes we got.

	cmp	cx,RUNT			;check legal packet size
	jb	recv_err
	cmp	cx,GIANT
	ja	recv_err

	push	cx
	call	recv_found		;do the first upcall.
	pop	cx

recv_complete_4:
	mov	ax,es			;is this pointer null?
	or	ax,di
	je	recv_discard		;yes - just free the frame.

	push	es			;remember where the buffer pointer is.
	push	di

	mov	bx,cx			;save the count.
	mov	cx,ETHER_BUFF_LEN/2	;move the data over.
	mov	si,offset ether_buff
	rep	movsw

	loadport			;restore the I/O port.
	setport	PORT_RxFIFO
	mov	cx,bx			;restore the count.
	sub	cx,ETHER_BUFF_LEN	;but leave off what we've already copied.

;	 cmp	 is_386,0
;	 jne	 io_input_386
io_input_286:
	push	cx
	shr	cx,1
;	 rep	 insw

;start 8086 code
l_input:
	in	ax, dx
	stosw
	loop l_input
;end 8086 code

	pop	cx
	jnc	io_input_286_1		;go if the count was even.
;	 insb				 ;get that last byte.

;start 8086 code
	in al, dx
	stosb
;end 8086 code

	in	al,dx			;and get the pad byte.
	test	cx,2			;even number of words?
	jne	io_input_done		;no.
	in	ax,dx			;yes, get the pad word.
	jmp	short io_input_done
io_input_286_1:
	test	cx,2			;odd number of words?
	je	io_input_done		;no.
	in	ax,dx			;yes, get the pad word.
	jmp	short io_input_done

;io_input_386:
;	 .386
;	 push	 eax
;	 push	 cx			 ;first, get all the full words.
;	 shr	 cx,2
;	 rep	 insd
;	 pop	 cx
;	 test	 cx,3			 ;even number of dwords?
;	 je	 io_input_386_one_byte	 ;yes.
;	 in	 eax,dx			 ;no, get the partial word.
;	 test	 cx,2			 ;a full word to be stored?
;	 je	 io_input_386_one_word
;	 stosw				 ;yes, store it,
;	 shr	 eax,16			 ;and move over by a word.
;io_input_386_one_word:

;	 test	 cx,1			 ;a full byte to be stored?
;	 je	 io_input_386_one_byte
;	 stosb				 ;yes, store it.
;io_input_386_one_byte:
;	 pop	 eax
;	 .286

io_input_done:

	mov	cx,bx			;restore the count.
	pop	si
	pop	ds
	assume	ds:nothing
	call	recv_copy		;tell them that we copied it.

	mov	ax,cs			;restore our ds.
	mov	ds,ax
	assume	ds:code

recv_discard:
	loadport
	setport	PORT_CmdStatus
        pushf
        cli
	mov	ax,CMD_RXDISCARD
	out	dx,ax
recv_discard_1:
	in	ax,dx			;wait for the command to finish.
	test	ax,ST_BUSY
	jne	recv_discard_1
        popf

	mov	early_bytes,0

	jmp	recv_another
recv_exit:
	ret


	public	timer_isr
timer_isr:
;if the first instruction is an iret, then the timer is not hooked
	iret

;any code after this will not be kept.  Buffers used by the program, if any,
;are allocated from the memory between end_resident and end_free_mem.
	public end_resident,end_free_mem
end_resident	label	byte
end_free_mem	label	byte


	public	usage_msg, mca_usage_msg
mca_usage_msg	label	byte
usage_msg	db	"usage: 3c509 [options] <packet_int_no> [id_port]",CR,LF,'$'

	public	copyright_msg
copyright_msg	db	"Packet driver for a 3c509, version ",'0'+(majver / 10),'0'+(majver mod 10),".",'0'+version,CR,LF
		db	"Portions Copyright 1992, Crynwr Software",CR,LF
		db	"8088/8086 support by Nestor a.k.a. DistWave",CR,LF,'$'
no_isa_msg	db	CR,LF
		db	"No 3c509 found.  Use a different id_port value.  Default is 0x110.",CR,LF,'$'
reading_msg	db	"Reading EEPROM.",'$'

multiple_msg	db	"Multiple 3C509s found, specify i/o port",CR,LF,'$'
wrong_port_msg	db	"No 3C509 board found at specified i/o port",CR,LF,'$'
eisa_in_isa_msg	db	"EISA configured board in ISA slot",CR,LF,'$'

int_no_name	db	"Interrupt number ",'$'
io_addr_name	db	"I/O port ",'$'
aui_xcvr_msg	db	"Using AUI transceiver",CR,LF,'$'
bnc_xcvr_msg	db	"Using BNC (10Base2) transceiver",CR,LF,'$'
tp_xcvr_msg	db	"Using Twisted Pair (10BaseT) transceiver",CR,LF,'$'
id_port_name	db	"ID port ",'$'

;called when you're ready to receive interrupts.
	extrn	set_recv_isr: near

;enter with si -> argument string, di -> dword to store.
;if there is no number, don't change the number.
	extrn	get_number: near

;enter with dx -> argument string, di -> dword to print.
	extrn	print_number: near

;-> the unique Ethernet address of the card.  Filled in by the etopen routine.
	extrn	rom_address: byte

;-> current address.  Normally the same as rom_address, unless changed
;by the set_address() call.
	extrn	my_address: byte

address_configuration	dw	?
resource_configuration	dw	?

is_10base2	db	0
is_10baseT	db	0

id_port		dw	110h,0
scratch		dw	0,0		;for multi-board support
board_number	db	0

;print the character in al.
	extrn	chrout: near

;print a crlf
	extrn	crlf: near

;parse_args is called with si -> first parameter (CR if none).
	public	parse_args
parse_args:
;exit with nc if all went well, cy otherwise.
	mov	di,offset id_port
	call	get_number
	clc
	ret


	public	etopen
etopen:
;initialize the driver.  Fill in rom_address with the assigned address of
;the board.  Exit with nc if all went well, or cy, dx -> $ terminated error msg.
;if all is okay,
;	 cmp	 is_186,0		 ;this version requires a 186 or better.
;	 jne	 etopen_1
;	 mov	 dx,offset needs_186_msg
;	 stc
;	 ret
;etopen_1:

;	 cmp	 is_386,0		 ;can we do a real insd?
;	 je	 etopen_2
;overlay the repinsd routine with a real "rep insd;nop"
;	 mov	 word ptr repinsd+0,066h+0f3h*256
;	 mov	 word ptr repinsd+2,06dh+090h*256
;etopen_2:

	cmp	is_eisa,0
	jne	etopen_eisa
	jmp	etopen_isa
etopen_eisa:
	mov	cx,0fh
eisa_search:
	mov	dx,cx			;move it into the first nibble.
	shl	dx,12
	or	dx,0c80h
	in	ax,dx			;look for the manufacturer's ID
	cmp	ax,EISA_MANUFACTURER_ID
	jne	eisa_search_1
	inc	dx
	inc	dx
	in	ax,dx			;look for the product ID
	and	ax,PRODUCT_ID_MASK
	cmp	ax,ISA_PRODUCT_ID
	je	eisa_found
eisa_search_1:
	loop	eisa_search
	jmp	etopen_isa		;;; if it's not EISA-configured, try ISA.

eisa_found:
	and	dx,0f000h
	mov	io_addr,dx

	loadport
	setwin	WNO_SETUP

	setport	PORT_CfgAddress
	in	ax,dx
	mov	address_configuration,ax

	setport	PORT_CfgResource
	in	ax,dx
	mov	resource_configuration,ax

	setport	PORT_EECmd
	mov	si,offset read_ee_eisa
	call	read_eaddr

	jmp	have_configuration

etopen_isa:
	and	id_port,01f0h		;isolate only the bits we can use.
	call	write_id_pat

	mov	al,ID_GLOBAL_RESET	;reset the adapter.
	out	dx,al
	call	delay_27_5ms		;wait for 310 us.

	call	write_id_pat

	mov	al,SET_TAG_REGISTER
	out	dx,al

	push	dx
	mov	dx,offset reading_msg
	mov	ah,9
	int	21h
	pop	dx

	xor	al,al
	xor	di,di
	mov	cx,16
read_isa_checksum:
	push	ax
	push	cx
	call	read_ee_isa
	mov	bx,ax
	mov	al,'.'
	call	chrout
	pop	cx
	pop	ax
	cmp	al,3
	jne	read_isa_checksum_not_3
	push	bx
	and	bx,0f0ffh
	cmp	bx,09050h
	pop	bx
	jne	not_found_isa
read_isa_checksum_not_3:
	cmp	al,7
	jne	read_isa_checksum_not_7
	cmp	bx,6d50h
	jne	not_found_isa
read_isa_checksum_not_7:
	cmp	al,8
	je	read_isa_checksum_1
	cmp	al,9
	je	read_isa_checksum_1
	cmp	al,0dh
	je	read_isa_checksum_1
	cmp	al,0fh			;if it's the checksum itself, just xor.
	je	read_isa_checksum_2
	xor	bh,bl			;accumulate checksum in high byte.
	xor	bl,bl			;leave low byte alone.
	jmp	short read_isa_checksum_2
read_isa_checksum_1:
	xor	bl,bh			;accumulate checksum in low byte.
	xor	bh,bh			;leave high byte alone.
read_isa_checksum_2:
	xor	di,bx			;include previous checksum.

	inc	al			;and go to the next register.
	loop	read_isa_checksum

	call	crlf

	or	di,di			;did the checksum compare?
	je	found_isa		;yes.
not_found_isa:
	mov	dx,offset no_isa_msg
	stc
	ret

found_isa:
	mov	si,offset read_ee_isa
	call	read_eaddr

	mov	al,EE_ADDR_CONFIGURATION
	call	read_ee_isa
	mov	address_configuration,ax

	mov	al,EE_RESOURCE_CONFIGURATION
	call	read_ee_isa
	mov	resource_configuration,ax

	mov	al,ACTIVATE_VULCAN
	out	dx,al

	mov	ax,address_configuration
	and	ax,1fh
	mov	cl,4
	shl	ax,cl
	add	ax,MIN_IO_BASE_ADDR
	mov	io_addr,ax

have_configuration:
	mov	ax,address_configuration
	and	ax,BNC_XCVR or TP_XCVR or AUI_XCVR	;include all the bits.
	cmp	ax,BNC_XCVR		;does it match BNC?
	jne	not_10base2
	inc	is_10base2
not_10base2:
	cmp	ax,TP_XCVR		;does it match TP?
	jne	not_10baseT
	inc	is_10baseT
not_10baseT:

	mov	bx,resource_configuration
	mov	cl,12			;move it over where we need it.
	shr	bx,cl
	mov	int_no,bl

	loadport
	setwin	WNO_DIAGNOSTICS
	setport	PORT_MediaStatus
	in	ax,dx
	or	ax,MEDIA_LBEATENABLE or MEDIA_JABBERENABLE
	out	dx,ax

	setwin	WNO_SETUP		;select Window 0

	mov	ax,CMD_TXENABLE		;Enable the transmitter
	out	dx,ax

	mov	ax,CMD_RXENABLE		;Enable the receiver
	out	dx,ax

;Enable RX Complete interrupts
	mov	ax,CMD_SETINTMASK + INT_RXCOMPLETE
	;mov	ax,CMD_SETINTMASK + INT_RXCOMPLETE + INT_RXEARLY
	out	dx,ax

	mov	ax,CMD_SETRZMASK + 0feh	;Enable all the status bits.
	out	dx,ax

	mov	ax,CMD_SETTXSTART + 0	;start transmitting after this many bytes.
	out	dx,ax

	mov	ax,CMD_SETRXEARLY + 0	;receive after this many bytes.
	out	dx,ax

	cmp	is_10base2,0		;coax?
	je	not_10base2_1		;no.
	mov	ax,CMD_STARTINTXCVR	;start internal transciever
	out	dx,ax
	call	delay_27_5ms
not_10base2_1:

	setport	PORT_CfgControl		;position to the CCR
	mov	al,ENABLE_ADAPTER	;Enable the adapter.
	out	dx,al

	call	rcv_mode_3

	mov	si,offset rom_address	;set our address.
	mov	cx,EADDR_LEN
	call	set_address_4
;sets the window to WNO_OPERATING.

	call	set_recv_isr

	mov	al, int_no		; Get board's interrupt vector
	add	al, 8
	cmp	al, 8+8			; Is it a slave 8259 interrupt?
	jb	set_int_num		; No.
	add	al, 70h - 8 - 8		; Map it to the real interrupt.
set_int_num:
	xor	ah, ah			; Clear high byte
	mov	int_num, ax		; Set parameter_list int num.

	clc
	ret
;if we got an error,
	stc
	ret


write_id_pat:
;write the 3c509 ID pattern to the ID port.
	mov	dx,id_port
	xor	al,al
	out	dx,al			;select the ID port.
	out	dx,al			;reset hardware pattern generator
	mov	cx,0ffh
	mov	al,0ffh
write_id_pat_1:
	out	dx,al			;keep writing matching values...
	shl	al,1
	jnc	write_id_pat_2
	xor	al,0cfh
write_id_pat_2:
	loop	write_id_pat_1
	ret

read_eaddr:
;enter with dx = eeprom register, si -> routine to read eeprom.
	push	cs
	pop	es
	mov	di,offset rom_address

	mov	al,EE_TCOM_NODE_ADDR_WORD0	;read the Ethernet address.
	call	si
	xchg	ah,al
	stosw
	mov	al,EE_TCOM_NODE_ADDR_WORD1
	call	si
	xchg	ah,al
	stosw
	mov	al,EE_TCOM_NODE_ADDR_WORD2
	call	si
	xchg	ah,al
	stosw
	ret


read_ee_eisa:
;enter with al = EEPROM address to read, dx = PORT_EECmd
;exit with ax = data.
	or	al,READ_EEPROM
	out	dx,al
read_ee_eisa_1:
	in	ax,dx
	test	ax,EE_BUSY
	jnz	read_ee_eisa_1
	add	dx,PORT_EEData - PORT_EECmd	;move to data register.
	in	ax,dx
	add	dx,PORT_EECmd - PORT_EEData	;move back to command register.
	ret


read_ee_isa:
;enter with al = EEPROM address to read, dx = address of ID port.
;exit with ax = data, cx = 0.
	push	bx
	or	al,READ_EEPROM
	out	dx,al
;wait 400 us here.
	call	delay_27_5ms
	mov	cx,16
read_ee_isa_1:
	in	al,dx
	shr	al,1			;put it into the carry.
	rcl	bx,1			;shift it into bx.
	loop	read_ee_isa_1
	mov	ax,bx
	pop	bx
	ret


delay_27_5ms:
;delay one timeout period, which is 27.5 ms.
	mov	ax,1
delay:
;delay AX timeout periods, each of which is 27.5 ms.
	call	set_timeout
delay_1:
	call	do_timeout
	jnz	delay_1
	ret


	public	print_parameters
print_parameters:
;echo our command-line parameters
	mov	di,offset int_no
	mov	dx,offset int_no_name
	call	print_number
	mov	di,offset io_addr
	mov	dx,offset io_addr_name
	call	print_number
	mov	dx,offset aui_xcvr_msg
	cmp	is_10base2,0		;coax?
	je	print_parameters_1
	mov	dx,offset bnc_xcvr_msg
print_parameters_1:
	cmp	is_10baseT,0		;tp?
	je	print_parameters_2
	mov	dx,offset tp_xcvr_msg
print_parameters_2:
	mov	ah,9
	int	21h
	mov	di,offset id_port
	mov	dx,offset id_port_name
	call	print_number
	ret

code	ends

	end
