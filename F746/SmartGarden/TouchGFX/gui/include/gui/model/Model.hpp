#ifndef MODEL_HPP
#define MODEL_HPP

#include <gui/model/ModelListener.hpp>

class Model
{
public:
    Model();
    void tick();
    void bind(ModelListener* listener) { modelListener = listener; }

private:
    ModelListener* modelListener;
    float temperature;
    float humidity;
    int   light;
    bool  soilWet;
    bool  fanOn;
};

#endif
