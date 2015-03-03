with Types; use Types;

package Pid_Pack
with SPARK_Mode
is
   --  Constants
   PID_ROLL_RATE_KP : constant := 70.0;
   PID_ROLL_RATE_KI : constant := 0.0;
   PID_ROLL_RATE_KD : constant := 0.0;
   PID_ROLL_RATE_INTEGRATION_LIMIT : constant := 100.0;

   PID_PITCH_RATE_KP : constant := 70.0;
   PID_PITCH_RATE_KI : constant := 0.0;
   PID_PITCH_RATE_KD : constant := 0.0;
   PID_PITCH_RATE_INTEGRATION_LIMIT : constant := 100.0;

   PID_YAW_RATE_KP : constant := 70.0;
   PID_YAW_RATE_KI : constant := 50.0;
   PID_YAW_RATE_KD : constant := 0.0;
   PID_YAW_RATE_INTEGRATION_LIMIT : constant := 500.0;

   PID_ROLL_KP : constant := 3.5;
   PID_ROLL_KI : constant := 2.0;
   PID_ROLL_KD : constant := 0.0;
   PID_ROLL_INTEGRATION_LIMIT : constant := 20.0;

   PID_PITCH_KP : constant := 3.5;
   PID_PITCH_KI : constant := 2.0;
   PID_PITCH_KD : constant := 0.0;
   PID_PITCH_INTEGRATION_LIMIT : constant := 20.0;

   PID_YAW_KP : constant := 0.0;
   PID_YAW_KI : constant := 0.0;
   PID_YAW_KD : constant := 0.0;
   PID_YAW_INTEGRATION_LIMIT : constant := 360.0;

   DEFAULT_PID_INTEGRATION_LIMIT : constant := 5000.0;

   HIGH_DT_LIMIT : constant := 0.999;
   LOW_DT_LIMIT  : constant := 0.001;

   --  Types
   type Pid_Object is record
      Desired     : Allowed_Floats;       --  Set point
      Error       : Float;                --  Error
      Prev_Error  : Float;                --  Previous Error
      Integ       : Float;                --  Integral
      Deriv       : Float;                --  Derivative
      Kp          : Allowed_Floats;       --  Proportional Gain
      Ki          : Allowed_Floats;       --  Integral Gain
      Kd          : Allowed_Floats;       --  Derivative Gain
      Out_P       : Float;                --  Proportional Output (debug)
      Out_I       : Float;                --  Integral Output (debug)
      Out_D       : Float;                --  Derivative Output (debug)
      I_Limit     : Allowed_Floats;       --  Integral Limit
      I_Limit_Low : Allowed_Floats;       --  Integral Limit
      Dt          : Allowed_Floats;       --  Delta Time
   end record;

   --  Procedures and Functions

   --  PID object initialization.
   procedure Pid_Init (Pid : out Pid_Object;
                       Desired : Allowed_Floats;
                       Kp : Allowed_Floats;
                       Ki : Allowed_Floats;
                       Kd : Allowed_Floats;
                       Dt : Allowed_Floats)
     with
       Depends => (Pid => (Desired, Kp, Ki, Kd, Dt)),
       Pre => (Dt > LOW_DT_LIMIT and Dt < HIGH_DT_LIMIT);

   --  Reset the PID error values.
   procedure Pid_Reset (Pid : in out Pid_Object);

   --  Update the PID parameters. Set 'UpdateError' to 'False' is error has been set
   --  previously for a special calculation with 'PidSetError'.
   procedure Pid_Update (Pid : in out Pid_Object;
                         Measured : Allowed_Floats;
                         Update_Error : Boolean)
     with
       Depends => (Pid => (Measured, Pid, Update_Error)),
       Pre => (Pid.Dt > LOW_DT_LIMIT and Pid.Dt < HIGH_DT_LIMIT) and then
     Pid.Error in 3.0 * Allowed_Floats'First .. 3.0 * Allowed_Floats'Last and then
     Pid.Prev_Error in 3.0 * Allowed_Floats'First .. 3.0 * Allowed_Floats'Last and then
     Pid.Integ in Pid.I_Limit_Low .. Pid.I_Limit;

   --  Return the PID output. Must be called after 'PidUpdate'.
   function Pid_Get_Output (Pid : Pid_Object) return Float
     with
       Pre => (Pid.Out_P in Allowed_Floats'First * Allowed_Floats'Last .. Allowed_Floats'Last * Allowed_Floats'Last) and then
     (Pid.Out_I in Allowed_Floats'First * Allowed_Floats'Last .. Allowed_Floats'Last * Allowed_Floats'Last) and then
     (Pid.Out_D in Allowed_Floats'First * Allowed_Floats'Last .. Allowed_Floats'Last * Allowed_Floats'Last);

   --  Find out if the PID is active.
   function Pid_Is_Active (Pid : Pid_Object) return Boolean;

   --  Set a new set point for the PID to track.
   procedure Pid_Set_Desired (Pid : in out Pid_Object;
                              Desired : Allowed_Floats)
     with
       Post => Pid = Pid'Old'Update (Desired => Desired);

   --  Get the PID desired set point.
   function Pid_Get_Desired (Pid : Pid_Object) return Float;

   --  Set the integral limit.
   procedure Pid_Set_Integral_Limit (Pid : in out Pid_Object;
                                     Limit : Allowed_Floats)
     with
       Post => Pid = Pid'Old'Update (I_Limit => Limit);

   --  Set the integral limit.
   procedure Pid_Set_Integral_Limit_Low (Pid : in out Pid_Object;
                                         Limit_Low : Allowed_Floats)
     with
       Post => Pid = Pid'Old'Update (I_Limit_Low => Limit_Low);

   --  Set the new error. Used if special calculation is needed.
   procedure Pid_Set_Error (Pid : in out Pid_Object;
                            Error : Float)
     with
       Post => Pid = Pid'Old'Update (Error => Error);

   --  Set a new proprtional gain for the PID.
   procedure Pid_Set_Kp (Pid : in out Pid_Object;
                         Kp : Allowed_Floats)
     with
       Post => Pid = Pid'Old'Update (Kp => Kp);

   --  Set a new integral gain for the PID.
   procedure Pid_Set_Ki (Pid : in out Pid_Object;
                         Ki : Allowed_Floats)
     with
       Post => Pid = Pid'Old'Update (Ki => Ki);

   --  Set a new derivative gain for the PID.
   procedure Pid_Set_Kd (Pid : in out Pid_Object;
                         Kd : Allowed_Floats)
     with
       Post => Pid = Pid'Old'Update (Kd => Kd);

   --   Set a new dt gain for the PID. Defaults to IMU_UPDATE_DT upon construction.
   procedure Pid_Set_Dt (Pid : in out Pid_Object;
                         Dt : Allowed_Floats)
     with
       Post => Pid = Pid'Old'Update (Dt => Dt);

end Pid_Pack;
