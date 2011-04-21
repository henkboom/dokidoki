#ifndef DOKIDOKI_PHYSICS_HPP
#define DOKIDOKI_PHYSICS_HPP

#include <btBulletDynamicsCommon.h>

extern "C" {
    #include <lua.h>
    #include <lualib.h>
    #include <lauxlib.h>
}

typedef struct _physics_component_s physics_component_s;

class MotionState : public btMotionState
{
    public:
    MotionState(lua_State *L, int component_ref);
    void getWorldTransform(btTransform &transform) const;
    void setWorldTransform(const btTransform &transform);

    private:
    lua_State *L;
    int component_ref;
};

void physics_add_rigid_body(physics_component_s *physics, btRigidBody *body);

#endif
