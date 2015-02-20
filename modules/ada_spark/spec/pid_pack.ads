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

   --  Types
   type Pid_Object is record
      Desired : Float;           --  Set point
      Error : Float;             --  Error
      Prev_Error : Float;         --  Previous Error
      Integ : Float;             --  Integral
      Deriv : Float;             --  Derivative
      Kp : Float;                --  Proportional Gain
      Ki : Float;                --  Integral Gain
      Kd : Float;                --  Derivative Gain
      Out_P : Float;              --  Proportional Output (debug)
      Out_I : Float;              --  Integral Output (debug)
      Out_D : Float;              --  Derivative Output (debug)
      I_Limit : Float;            --  Integral Limit
      I_Limit_Low : Float;         --  Integral Limit
      Dt : Float;                --  Delta Time
   end record;

   --  Procedures and Functions

   --  PID object initialization
   procedure Pid_Init(Pid : out Pid_Object;
                      Desired : Float;
                      Kp : Float;
                      Ki : Float;
                      Kd : Float;
                      Dt : Float);

   --  Reset the PID error values
   procedure Pid_Reset(Pid : in out Pid_Object);

   --  Update the PID parameters. Set 'UpdateError' to 'False' is error has been set
   --  previously for a special calculation with 'PidSetError'
   procedure  Pid_Update(Pid : in out Pid_Object;
                         Measured : Float;
                         Update_Error : Boolean);

   --  Return the PID output. Must be called after 'PidUpdate'
   function Pid_Get_Output(Pid : in Pid_Object) return Float;

   --  Find out if the PID is active
   function Pid_Is_Active(Pid : in Pid_Object) return Boolean;

   --  Set a new set point for the PID to track
   procedure Pid_Set_Desired(Pid : in out Pid_Object;
                           Desired : Float);

   --  Get the PID desired set point
   function Pid_Get_Desired(Pid : in Pid_Object) return Float;

   --  Set the integral limit
   procedure Pid_Set_Integral_Limit(Pid : in out Pid_Object;
                                    Limit : Float);

   --  Set the integral limit
   procedure Pid_Set_Integral_Limit_Low(Pid : in out Pid_Object;
                                        Limit_Low : Float);

   --  Set the new error. Used if special calculation is needed.
   procedure Pid_Set_Error(Pid : in out Pid_Object;
                         Error : Float);

   --  Set a new proprtional gain for the PID
   procedure Pid_Set_Kp(Pid : in out Pid_Object;
                        Kp : Float);

   --  Set a new integral gain for the PID
   procedure Pid_Set_Ki(Pid : in out Pid_Object;
                        Ki : Float);

   --  Set a new derivative gain for the PID
   procedure Pid_Set_Kd(Pid : in out Pid_Object;
                        Kd : Float);

   --   Set a new dt gain for the PID. Defaults to IMU_UPDATE_DT upon construction
   procedure Pid_Set_Dt(Pid : in out Pid_Object;
                        Dt : Float);

end Pid_Pack;
