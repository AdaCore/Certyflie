------------------------------------------------------------------------------
--                              Certyflie                                   --
--                                                                          --
--                     Copyright (C) 2015-2016, AdaCore                     --
--                                                                          --
--  This library is free software;  you can redistribute it and/or modify   --
--  it under terms of the  GNU General Public License  as published by the  --
--  Free Software  Foundation;  either version 3,  or (at your  option) any --
--  later version. This library is distributed in the hope that it will be  --
--  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    --
--                                                                          --
--  As a special exception under Section 7 of GPL version 3, you are        --
--  granted additional permissions described in the GCC Runtime Library     --
--  Exception, version 3.1, as published by the Free Software Foundation.   --
--                                                                          --
--  You should have received a copy of the GNU General Public License and   --
--  a copy of the GCC Runtime Library Exception along with this program;    --
--  see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see   --
--  <http://www.gnu.org/licenses/>.                                         --
--                                                                          --
--  As a special exception, if other files instantiate generics from this   --
--  unit, or you link this unit with other files to produce an executable,  --
--  this  unit  does not  by itself cause  the resulting executable to be   --
--  covered by the GNU General Public License. This exception does not      --
--  however invalidate any other reasons why the executable file  might be  --
--  covered by the  GNU Public License.                                     --
------------------------------------------------------------------------------

with Safety; use Safety;

package body Pid
with SPARK_Mode
is

   --------------
   -- Pid_Init --
   --------------

   procedure Pid_Init
     (Pid          : out Pid_Object;
      Desired      : T_Input;
      Kp           : T_Coeff;
      Ki           : T_Coeff;
      Kd           : T_Coeff;
      I_Limit_Low  : T_I_Limit;
      I_Limit_High : T_I_Limit;
      Dt           : T_Delta_Time) is
   begin
      Pid.Desired := Desired;
      Pid.Error := 0.0;
      Pid.Prev_Error := 0.0;
      Pid.Integ := 0.0;
      Pid.Deriv := 0.0;
      Pid.Kp := Kp;
      Pid.Ki := Ki;
      Pid.Kd := Kd;
      Pid.Out_P := 0.0;
      Pid.Out_I := 0.0;
      Pid.Out_D := 0.0;
      Pid.I_Limit_Low  := I_Limit_Low;
      Pid.I_Limit_High := I_Limit_High;
      Pid.Dt := Dt;
   end Pid_Init;

   ---------------
   -- Pid_Reset --
   ---------------

   procedure Pid_Reset (Pid : in out Pid_Object) is
   begin
      Pid.Error := 0.0;
      Pid.Prev_Error := 0.0;
      Pid.Integ := 0.0;
      Pid.Deriv := 0.0;
   end Pid_Reset;

   ----------------
   -- Pid_Update --
   ----------------

   procedure Pid_Update
     (Pid          : in out Pid_Object;
      Measured     : T_Input;
      Update_Error : Boolean) is
   begin
      if Update_Error then
         Pid.Error := Pid.Desired - Measured;
      end if;

      pragma Assert (Pid.Error * Pid.Dt in
                       T_Error'First * 2.0 * T_Delta_Time'Last ..
                         T_Error'Last * 2.0 * T_Delta_Time'Last);

      Pid.Integ := Saturate (Pid.Integ + Pid.Error * Pid.Dt,
                             Pid.I_Limit_Low,
                             Pid.I_Limit_High);

      Pid.Deriv := (Pid.Error - Pid.Prev_Error) / Pid.Dt;

      Pid.Out_P := Pid.Kp * Pid.Error;

      pragma Assert (Pid.Integ in T_I_Limit'First * 1.0 ..
                       T_I_Limit'Last * 1.0);
      Pid.Out_I := Pid.Ki * Pid.Integ;

      Pid.Out_D := Pid.Kd * Pid.Deriv;

      Pid.Prev_Error := Pid.Error;
   end Pid_Update;

   --------------------
   -- Pid_Get_Output --
   --------------------

   function Pid_Get_Output (Pid : Pid_Object) return Float is
     (Pid.Out_P + Pid.Out_I + Pid.Out_D);

   -------------------
   -- Pid_Is_Active --
   -------------------

   function Pid_Is_Active (Pid : Pid_Object) return Boolean
   is
      Is_Active : Boolean := True;
   begin
      if Pid.Kp < 0.0001 and Pid.Ki < 0.0001 and Pid.Kd < 0.0001 then
         Is_Active := False;
      end if;

      return Is_Active;
   end Pid_Is_Active;

   ---------------------
   -- Pid_Set_Desired --
   ---------------------

   procedure Pid_Set_Desired
     (Pid     : in out Pid_Object;
      Desired : T_Input) is
   begin
      Pid.Desired := Desired;
   end Pid_Set_Desired;

   ---------------------
   -- Pid_Get_Desired --
   ---------------------

   function Pid_Get_Desired (Pid : Pid_Object) return Float is
     (Pid.Desired);

   -------------------
   -- Pid_Set_Error --
   -------------------

   procedure Pid_Set_Error
     (Pid   : in out Pid_Object;
      Error : T_Error) is
   begin
      Pid.Error := Error;
   end Pid_Set_Error;

   ----------------
   -- Pid_Set_Kp --
   ----------------

   procedure Pid_Set_Kp
     (Pid : in out Pid_Object;
      Kp  : T_Coeff) is
   begin
      Pid.Kp := Kp;
   end Pid_Set_Kp;

   ----------------
   -- Pid_Set_Ki --
   ----------------

   procedure Pid_Set_Ki
     (Pid : in out Pid_Object;
      Ki  : T_Coeff) is
   begin
      Pid.Ki := Ki;
   end Pid_Set_Ki;

   ----------------
   -- Pid_Set_Kd --
   ----------------

   procedure Pid_Set_Kd
     (Pid : in out Pid_Object;
      Kd  : T_Coeff) is
   begin
      Pid.Kd := Kd;
   end Pid_Set_Kd;

   -------------------------
   -- Pid_Set_I_Limit_Low --
   -------------------------

   procedure Pid_Set_I_Limit_Low
     (Pid          : in out Pid_Object;
      I_Limit_Low  : T_I_Limit) is
   begin
      Pid.I_Limit_Low := I_Limit_Low;
   end Pid_Set_I_Limit_Low;

   --------------------------
   -- Pid_Set_I_Limit_High --
   --------------------------

   procedure Pid_Set_I_Limit_High
     (Pid            : in out Pid_Object;
      I_Limit_High   : T_I_Limit) is
   begin
      Pid.I_Limit_High := I_Limit_High;
   end Pid_Set_I_Limit_High;

   ----------------
   -- Pid_Set_Dt --
   ----------------

   procedure Pid_Set_Dt
     (Pid : in out Pid_Object;
      Dt  : T_Delta_Time) is
   begin
      Pid.Dt := Dt;
   end Pid_Set_Dt;

end Pid;
