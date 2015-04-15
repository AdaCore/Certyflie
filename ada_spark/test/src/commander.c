#include <stdint.h>
#include <stdbool.h>

typedef enum
{
  RATE,
  ANGLE
} RPYType;

void commanderInit(void)
{
}

bool commanderTest(void)
{
}

void commanderWatchdog(void)
{
}

uint32_t commanderGetInactivityTime(void)
{
  return 0;
}

void commanderGetRPY(float* eulerRollDesired, float* eulerPitchDesired, float* eulerYawDesired)
{
  *eulerRollDesired = 0.0;
  *eulerPitchDesired = 0.0;
  *eulerYawDesired = 0.0;
}

void commanderGetRPYType(RPYType* rollType, RPYType* pitchType, RPYType* yawType)
{
  *rollType = ANGLE;
  *pitchType = ANGLE;
  *yawType = RATE;
}

void commanderGetThrust(uint16_t* thrust)
{
  *thrust = 0;
}

void commanderGetAltHold(bool* altHold, bool* setAltHold, float* altHoldChange)
{
  *altHold = false;
  *setAltHold = false;
  *altHoldChange = 0.0;
}
