#include <gui/model/Model.hpp>
#include <gui/model/ModelListener.hpp>

#include <stdio.h>
#include <stdint.h>   // ← pour uint8_t
#include <string.h>   // ← pour memcpy

extern "C" {
    extern char     msg_ready_buffer[50];
    extern volatile uint8_t msg_ready_flag;
}

Model::Model() : modelListener(0), temperature(0), humidity(0), light(0), soilWet(false), fanOn(false)
{
}

#include <cstdlib> // Pour atof et atoi

void Model::tick()
{
	if (msg_ready_flag)
	{
	    msg_ready_flag = 0;

	    // On nettoie le début du buffer au cas où il y aurait un '#' ou un espace
	    char* cleanStart = strpbrk(msg_ready_buffer, "0123456789-");

	    if (cleanStart != NULL)
	    {
	        // On travaille sur le pointeur "propre"
	        char* token = strtok(cleanStart, ",");
	        if (token != NULL) {
	            temperature = (float)atof(token);
	        }

	        token = strtok(NULL, ",");
	        if (token != NULL) {
	            humidity = (float)atof(token);
	        }

	        token = strtok(NULL, ",");
	        if (token != NULL) {
	            light = atoi(token);
	        }

	        token = strtok(NULL, ",");
	        if (token != NULL) {
	            soilWet = (atoi(token) == 1);
	        }

	        token = strtok(NULL, ",");
	        if (token != NULL) {
	            fanOn = (atoi(token) == 1);
	        }
	    }
	}

    if (modelListener != 0)
    {
        modelListener->setNewData(temperature, humidity, light, soilWet, fanOn);
    }
}
