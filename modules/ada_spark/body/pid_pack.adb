package body Pid_Pack
  with SPARK_Mode
is

   procedure Pid_Init(Pid : out Pid_Object;
                      Desired : Float;
                      Kp : Float;
                      Ki : Float;
                      Kd : Float;
                      Dt : Float) is
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
      Pid.I_Limit := DEFAULT_PID_INTEGRATION_LIMIT;
      Pid.I_Limit_Low := - DEFAULT_PID_INTEGRATION_LIMIT;
      Pid.Dt := Dt;
   end Pid_Init;

   procedure Pid_Reset(Pid : in out Pid_Object) is
   begin
      Pid.Error := 0.0;
      Pid.Prev_Error := 0.0;
      Pid.Integ := 0.0;
      Pid.Deriv := 0.0;
   end Pid_Reset;

   procedure Pid_Update(Pid : in out Pid_Object;
                        Measured : Float;
                        Update_Error : Boolean) is
   begin
      if Update_Error then
         Pid.Error := Pid.Desired - Measured;
      end if;

      Pid.Integ := Pid.Integ + Pid.Error * Pid.Dt;

      if Pid.Integ > Pid.I_Limit then
         Pid.Integ := Pid.I_Limit;
      elsif Pid.Integ < Pid.I_Limit_Low then
         Pid.Integ := Pid.I_Limit_Low;
      end if;

      Pid.Deriv := (Pid.Error - Pid.Prev_Error) / Pid.Dt;

      Pid.Out_P := Pid.Kp * Pid.Error;
      Pid.Out_I := Pid.Ki * Pid.Integ;
      Pid.Out_D := Pid.Kd * Pid.Deriv;

      Pid.Prev_Error := Pid.Error;
   end Pid_Update;

   function Pid_Get_Output(Pid : in Pid_Object) return Float is
      (Pid.Out_P + Pid.Out_I + Pid.Out_D);

   function Pid_Is_Active(Pid : in Pid_Object) return Boolean is
      Is_Active : Boolean := True;
   begin
      if Pid.Kp < 0.0001 and Pid.Ki < 0.0001 and Pid.Kd < 0.0001 then
         Is_Active := False;
      end if;

      return Is_Active;
   end Pid_Is_Active;

   procedure Pid_Set_Desired(Pid : in out Pid_Object;
                             Desired : Float) is
   begin
      Pid.Desired := Desired;
   end Pid_Set_Desired;

   function Pid_Get_Desired(Pid : in Pid_Object) return Float is
      (Pid.Desired);

   procedure Pid_Set_Integral_Limit(Pid : in out Pid_Object;
                                    Limit : Float) is
   begin
      Pid.I_Limit := Limit;
    end Pid_Set_Integral_Limit;

    procedure Pid_Set_Integral_Limit_Low(Pid : in out Pid_Object;
                                         Limit_Low : Float) is
    begin
       Pid.I_Limit_Low := Limit_Low;
    end Pid_Set_Integral_Limit_Low;

   procedure Pid_Set_Error(Pid : in out Pid_Object;
                         Error : Float) is
   begin
      Pid.Error := Error;
   end Pid_Set_Error;

   procedure Pid_Set_Kp(Pid : in out Pid_Object;
                        Kp : Float) is
   begin
      Pid.Kp := Kp;
   end Pid_Set_Kp;

   procedure Pid_Set_Ki(Pid : in out Pid_Object;
                        Ki : Float) is
   begin
      Pid.Ki := Ki;
   end Pid_Set_Ki;

   procedure Pid_Set_Kd(Pid : in out Pid_Object;
                        Kd : Float) is
   begin
      Pid.Kd := Kd;
   end Pid_Set_Kd;

   procedure Pid_Set_Dt(Pid : in out Pid_Object;
                        Dt : Float) is
   begin
      Pid.Dt := Dt;
   end Pid_Set_Dt;
end Pid_Pack;
