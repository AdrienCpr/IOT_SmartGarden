#ifndef MODELLISTENER_HPP
#define MODELLISTENER_HPP

class Model;  // ← forward declaration, évite l'inclusion circulaire

class ModelListener
{
public:
    ModelListener() : model(0) {}
    virtual ~ModelListener() {}

    void bind(Model* m) { model = m; }

    virtual void setNewData(float t, float h, int l, bool s, bool f) {}

protected:
    Model* model;
};

#endif
