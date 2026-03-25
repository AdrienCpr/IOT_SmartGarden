#include <gui/screen1_screen/Screen1View.hpp>
#include "main.h"

Screen1View::Screen1View()
{
}

void Screen1View::setupScreen()
{
    Screen1ViewBase::setupScreen();

    Unicode::snprintf(textLuxBuffer, TEXTLUX_SIZE, "%d", 999);
    textLux.invalidate();

    Unicode::snprintf(textSolEtatBuffer, TEXTSOLETAT_SIZE, "%s", "TEST");
    textSolEtat.invalidate();

    gaugeTemp.setValue(35);
    gaugeTemp.invalidate();

    gaugeHum.setValue(75);
    gaugeHum.invalidate();
}

void Screen1View::tearDownScreen()
{
    Screen1ViewBase::tearDownScreen();
}

void Screen1View::updateValues(float t, float h, int l, bool s, bool f)
{
    // Jauges
    gaugeTemp.setValue((int)t);
    gaugeTemp.invalidate();
    gaugeHum.setValue((int)h);
    gaugeHum.invalidate();

    // Lumière
    Unicode::snprintf(textLuxBuffer, TEXTLUX_SIZE, "%d", l);
    textLux.invalidate();

    // Humidité Sol
    if (s) {
        Unicode::snprintf(textSolEtatBuffer, TEXTSOLETAT_SIZE, "HUMIDE");
    } else {
        Unicode::snprintf(textSolEtatBuffer, TEXTSOLETAT_SIZE, "SEC");
    }
    textSolEtat.invalidate();
}

void Screen1View::onFanButtonClicked()
{
    fanOn = !fanOn;   // toggle

    if (fanOn)
        UART6_SendCommand("FAN_ON");
    else
        UART6_SendCommand("FAN_OFF");
}
