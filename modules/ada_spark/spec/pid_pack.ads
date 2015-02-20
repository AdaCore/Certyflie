package Pid_Pack is
   -- Constants
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

   -- Types
   type PidObject is record
      Desired : Float;    -- Set point
      Error : Float := 0.0;      -- Error
      PrevError : Float := 0.0;  -- Previous Error
      Integ : Float := 0.0;      -- Integral
      Deriv : Float := 0.0;      -- Derivative
      Kp : Float;         -- Proportional Gain
      Ki : Float;         -- Integral Gain
      Kd : Float;         -- Derivative Gain
      OutP : Float;       -- Proportional Output (debug)
      OutI : Float;       -- Integral Output (debug)
      OutD : Float;       -- Derivative Output (debug)
      ILimit : Float;     -- Integral Limit
      ILimitLow : Float;  -- Integral Limit
      Dt : Float;         -- Delta Time
   end record;

   -- Procedures and Functions

   -- PID object initialization
   procedure PidInit(Pid : out PidObject;
                     Desired : Float;
                     Kp : Float;
                     Ki : Float;
                     Kd : Float;
                     Dt : Float);

   -- Reset the PID error values
   procedure PidReset(Pid : in out PidObject);

   -- Update the PID parameters. Set 'UpdateError' to 'False' is error has been set
   -- previously for a special calculation with 'PidSetError'
   function PidUpdate(Pid : in out PidObject;
                      Measured : Float;
                      UpdateError : Boolean) return Float;

   -- Find out if the PID is active
   function PidIsActive(Pid : in PidObject) return Boolean;

   -- Set a new set point for the PID to track
   procedure PidSetDesired(Pid : in out PidObject;
                           Desired : Float);

   -- Get the PID desired set point
   function PidGetDesired(Pid : in PidObject) return Float;

   -- Set the integral limit
   procedure PidSetIntegralLimit(Pid : in out PidObject;
                                 Limit : Float);

   -- Set the integral limit
   procedure PidSetIntegralLimitLow(Pid : in out PidObject;
                                    LimitLow : Float);

   -- Set the new error. Used if special calculation is needed.
   procedure PidSetError(Pid : in out PidObject;
                         Error : Float);

   -- Set a new proprtional gain for the PID
   procedure PidSetKp(Pid : in out PidObject;
                      Kp : Float);

   -- Set a new integral gain for the PID
   procedure PidSetKi(Pid : in out PidObject;
                      Ki : Float);

   -- Set a new derivative gain for the PID
   procedure PidSetKd(Pid : in out PidObject;
                      Kd : Float);

   --  Set a new dt gain for the PID. Defaults to IMU_UPDATE_DT upon construction
   procedure PidSetDt(Pid : in out PidObject;
                      Dt : Float);

end Pid_Pack;
