package body Pid_Pack is

   procedure PidInit(Pid : out PidObject;
                     Desired : Float;
                     Kp : Float;
                     Ki : Float;
                     Kd : Float;
                     Dt : Float) is
   begin
      Pid.Desired := Desired;
      Pid.Kp := Kp;
      Pid.Ki := Ki;
      Pid.Kd := Kd;
      Pid.ILimit := DEFAULT_PID_INTEGRATION_LIMIT;
      Pid.ILimitLow := - DEFAULT_PID_INTEGRATION_LIMIT;
      Pid.Dt := Dt;
   end PidInit;

   procedure PidReset(Pid : in out PidObject) is
   begin
      Pid.Error := 0.0;
      Pid.PrevError := 0.0;
      Pid.Integ := 0.0;
      Pid.Deriv := 0.0;
   end PidReset;

   function PidUpdate(Pid : in out PidObject;
                      Measured : Float;
                      UpdateError : Boolean) return Float is
      Output : Float := 0.0;
   begin
      if UpdateError then
         Pid.Error := Pid.Desired - Measured;
      end if;

      Pid.Integ := Pid.Integ + Pid.Error * Pid.Dt;

      if Pid.Integ > Pid.ILimit then
         Pid.Integ := Pid.ILimit;
      elsif Pid.Integ < Pid.ILimitLow then
         Pid.Integ := Pid.ILimitLow;
      end if;

      Pid.Deriv := (Pid.Error - Pid.PrevError) / Pid.Dt;

      Pid.OutP := Pid.Kp * Pid.Error;
      Pid.OutI := Pid.Ki * Pid.Integ;
      Pid.OutD := Pid.Kd * Pid.Deriv;

      Output := Pid.OutP + Pid.OutI + Pid.OutD;

      Pid.PrevError := Pid.Error;

      return Output;
   end PidUpdate;

   function PidIsActive(Pid : in PidObject) return Boolean is
      IsActive : Boolean := True;
   begin
      if Pid.Kp < 0.0001 and Pid.Ki < 0.0001 and Pid.Kd < 0.0001 then
         IsActive := False;
      end if;

      return IsActive;
   end PidIsActive;

   procedure PidSetDesired(Pid : in out PidObject;
                           Desired : Float) is
   begin
      Pid.Desired := Desired;
   end PidSetDesired;

   function PidGetDesired(Pid : in PidObject) return Float is
      (Pid.Desired);

   procedure PidSetIntegralLimit(Pid : in out PidObject;
                                 Limit : Float) is
   begin
      Pid.ILimit := Limit;
    end PidSetIntegralLimit;

    procedure PidSetIntegralLimitLow(Pid : in out PidObject;
                                     LimitLow : Float) is
    begin
       Pid.ILimitLow := LimitLow;
    end PidSetIntegralLimitLow;

   procedure PidSetError(Pid : in out PidObject;
                         Error : Float) is
   begin
      Pid.Error := Error;
   end PidSetError;

   procedure PidSetKp(Pid : in out PidObject;
                      Kp : Float) is
   begin
      Pid.Kp := Kp;
   end PidSetKp;

   procedure PidSetKi(Pid : in out PidObject;
                      Ki : Float) is
   begin
      Pid.Ki := Ki;
   end PidSetKi;

   procedure PidSetKd(Pid : in out PidObject;
                      Kd : Float) is
   begin
      Pid.Kd := Kd;
   end PidSetKd;

   procedure PidSetDt(Pid : in out PidObject;
                      Dt : Float) is
   begin
      Pid.Dt := Dt;
   end PidSetDt;
end Pid_Pack;
