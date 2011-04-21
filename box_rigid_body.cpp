#include <btBulletDynamicsCommon.h>

extern "C" {
    #include <lua.h>
    #include <lualib.h>
    #include <lauxlib.h>

    int luaopen_dokidoki_box_rigid_body(lua_State *L);
}

#include "physics.hpp"

int luaopen_dokidoki_box_rigid_body(lua_State *L)
{
    // fetch transform
    {
        lua_getfield(L, LUA_ENVIRONINDEX, "parent");
        lua_getfield(L, -1, "transform");
        lua_remove(L, -2);
        lua_setfield(L, LUA_ENVIRONINDEX, "transform");
    }

    // get physics component
    physics_component_s *physics;
    {
        lua_getfield(L, LUA_ENVIRONINDEX, "game");
        lua_getfield(L, -1, "physics");
        lua_remove(L, -2);
        lua_getfield(L, -1, "get_udata");
        lua_remove(L, -2);
        lua_call(L, 0, 1);
        physics = (physics_component_s *)lua_touserdata(L, -1);
        lua_pop(L, 1);
    }

    // create the motionstate and rigidbody
    lua_getfield(L, LUA_ENVIRONINDEX, "self");

    btMotionState *motion_state =
        new MotionState(L, luaL_ref(L, LUA_REGISTRYINDEX));

    btCollisionShape *shape = new btBoxShape(btVector3(0.1, 0.1, 0.1));
    btScalar mass = 1;
    btVector3 inertia(0, 0, 0);
    shape->calculateLocalInertia(mass, inertia);
    btRigidBody::btRigidBodyConstructionInfo rigid_body_ci(
        mass, motion_state, shape, inertia);
    btRigidBody* rigid_body = new btRigidBody(rigid_body_ci);

    // add to the world
    physics_add_rigid_body(physics, rigid_body);

    return 0;
}
