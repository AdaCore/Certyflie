--  Package implementing the link between
--  the two Crazyflie MCU

with Ada.Synchronous_Task_Control; use Ada.Synchronous_Task_Control;
with Ada.Unchecked_Conversion;
with System;

with Types;                        use Types;
with UART_Syslink;                 use UART_Syslink;

package Syslink is

   --  Global variables and constants

   --  Size of Syslink packet data.
   SYSLINK_MTU      : constant := 31;

   --  Size of the transmission buffer.
   SEND_BUFFER_SIZE : constant := 64;

   --  Synchronization bytes.
   SYSLINK_START_BYTE1 : constant T_Uint8 := 16#BC#;
   SYSLINK_START_BYTE2 : constant T_Uint8 := 16#CF#;

   --  Bitwise mask to get the group type of a packet/
   SYSLINK_GROUP_MASK : constant T_Uint8 := 16#F0#;

   --  Buffer used for transmission.
   Tx_Buffer : DMA_Data;

   --  Types

   --  Syslink packet group type.
   type Syslink_Packet_Group_Type is (SYSLINK_RADIO_GROUP,
                                      SYSLINK_PM_GROUP,
                                      SYSLINK_OW_GROUP);

   for Syslink_Packet_Group_Type use (SYSLINK_RADIO_GROUP => 16#00#,
                                      SYSLINK_PM_GROUP    => 16#10#,
                                      SYSLINK_OW_GROUP    => 16#20#);
   for Syslink_Packet_Group_Type'Size use 8;

   --  Syslink packet types.
   type Syslink_Packet_Type is (SYSLINK_RADIO_RAW,
                                SYSLINK_RADIO_CHANNEL,
                                SYSLINK_RADIO_DATARATE,
                                SYSLINK_RADIO_CONTWAVE,
                                SYSLINK_RADIO_RSSI,
                                SYSLINK_RADIO_ADDRESS,
                                SYSLINK_PM_SOURCE,
                                SYSLINK_PM_ONOFF_SWITCHOFF,
                                SYSLINK_PM_BATTERY_VOLTAGE,
                                SYSLINK_PM_BATTERY_STATE,
                                SYSLINK_PM_BATTERY_AUTOUPDATE,
                                SYSLINK_OW_SCAN,
                                SYSLINK_OW_GETINFO,
                                SYSLINK_OW_READ,
                                SYSLINK_OW_WRITE);
   for Syslink_Packet_Type use (SYSLINK_RADIO_RAW             => 16#00#,
                                SYSLINK_RADIO_CHANNEL         => 16#01#,
                                SYSLINK_RADIO_DATARATE        => 16#02#,
                                SYSLINK_RADIO_CONTWAVE        => 16#03#,
                                SYSLINK_RADIO_RSSI            => 16#04#,
                                SYSLINK_RADIO_ADDRESS         => 16#05#,
                                SYSLINK_PM_SOURCE             => 16#10#,
                                SYSLINK_PM_ONOFF_SWITCHOFF    => 16#11#,
                                SYSLINK_PM_BATTERY_VOLTAGE    => 16#12#,
                                SYSLINK_PM_BATTERY_STATE      => 16#13#,
                                SYSLINK_PM_BATTERY_AUTOUPDATE => 16#14#,
                                SYSLINK_OW_SCAN               => 16#20#,
                                SYSLINK_OW_GETINFO            => 16#21#,
                                SYSLINK_OW_READ               => 16#22#,
                                SYSLINK_OW_WRITE              => 16#23#);
   for Syslink_Packet_Type'Size use 8;

   --  Type for Syslink packet data.
   subtype Syslink_Data is T_Uint8_Array (1 .. SYSLINK_MTU);

   --  Type for Syslink packets.
   type Syslink_Packet is record
      Slp_Type : Syslink_Packet_Type;
      Length   : T_Uint8;
      Data     : Syslink_Data;
   end record;

   type Syslink_Rx_State is (WAIT_FOR_FIRST_START,
                             WAIT_FOR_SECOND_START,
                             WAIT_FOR_TYPE,
                             WAIT_FOR_LENGTH,
                             WAIT_FOR_DATA,
                             WAIT_FOR_CHKSUM_1,
                             WAIT_FOR_CHKSUM_2);

   --  Initialize the Syslink protocol.
   procedure Syslink_Init;

   --  Test the Syslink protocol.
   function Syslink_Test return Boolean;

   --  Send a packet to the nrf51 chip.
   procedure Syslink_Send_Packet (Sl_Packet : Syslink_Packet);

   --  Tasks and protected objects

   task type Syslink_Task_Type (Prio : System.Priority) is
      pragma Priority (Prio);
   end Syslink_Task_Type;

private

   --  Global variables

   Is_Init         : Boolean := False;
   Syslink_Access  : Suspension_Object;
   Dropped_Packets : Natural := 0;

   --  Procedures and functions

   function T_Uint8_To_Slp_Type is new Ada.Unchecked_Conversion
     (T_Uint8, Syslink_Packet_Type);

   --  Route the incoming packet by sending it to the appropriate layer
   --  (Radiolink, Power_Management etc.).
   procedure Syslink_Route_Incoming_Packet (Rx_Sl_Packet : Syslink_Packet);

end Syslink;
