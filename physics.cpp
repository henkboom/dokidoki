#include "physics.hpp"

#include <GL/glfw.h>

extern "C" {
    int luaopen_dokidoki_physics(lua_State *L);
}

struct _physics_component_s {
    btBroadphaseInterface *broadphase;
    btCollisionConfiguration *collision_configuration;
    btCollisionDispatcher *collision_dispatcher;
    btConstraintSolver *constraint_solver;
    btDiscreteDynamicsWorld *world;
};

//// btMotionState Implementation /////////////////////////////////////////////
MotionState::MotionState(lua_State *L, int component_ref) :
    L(L),
    component_ref(component_ref)
{
    // do nothing
}

static void l_tovect(lua_State *L, int index, double *x, double *y, double *z)
{
    lua_rawgeti(L, index, 1);
    *x = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_rawgeti(L, index, 2);
    *y = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_rawgeti(L, index, 3);
    *z = lua_tonumber(L, -1);
    lua_pop(L, 1);
}

static void l_pushvect(lua_State *L, double x, double y, double z)
{
    lua_getglobal(L, "require");
    lua_pushstring(L, "dokidoki.vect");
    lua_call(L, 1, 1);
    // just the 'vect' module on the stack

    lua_pushnumber(L, x);
    lua_pushnumber(L, y);
    lua_pushnumber(L, z);
    lua_call(L, 3, 1);

    // leave the resulting vector on the stack
}

static void l_toquaternion(
    lua_State *L, int index, double *w, double *x, double *y, double *z)
{
    lua_rawgeti(L, index, 1);
    *w = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_rawgeti(L, index, 2);
    *x = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_rawgeti(L, index, 3);
    *y = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_rawgeti(L, index, 4);
    *z = lua_tonumber(L, -1);
    lua_pop(L, 1);
}

static void l_pushquaternion(
    lua_State *L, double w, double x, double y, double z)
{
    lua_getglobal(L, "require");
    lua_pushstring(L, "dokidoki.quaternion");
    lua_call(L, 1, 1);
    // just the 'quaternion' module on the stack

    lua_pushnumber(L, w);
    lua_pushnumber(L, x);
    lua_pushnumber(L, y);
    lua_pushnumber(L, z);
    lua_call(L, 4, 1);

    // leave the resulting quaternion on the stack
}

void MotionState::getWorldTransform(btTransform &transform) const
{
    lua_rawgeti(L, LUA_REGISTRYINDEX, component_ref);
    lua_getfield(L, -1, "transform");
    lua_remove(L, -2);
    // the stack now contains just the transform component
    
    // get the origin
    {
        lua_getfield(L, -1, "pos");
        double x, y, z;
        l_tovect(L, -1, &x, &y, &z);
        lua_pop(L, 1);

        transform.setOrigin(btVector3(x, y, z));
    }

    // get the rotation
    {
        lua_getfield(L, -1, "orientation");
        double w, x, y, z;
        l_toquaternion(L, -1, &w, &x, &y, &z);
        lua_pop(L, 1);

        transform.setRotation(btQuaternion(x, y, z, w));
    }

    lua_pop(L, 1);
}

void MotionState::setWorldTransform(const btTransform &transform)
{
    lua_rawgeti(L, LUA_REGISTRYINDEX, component_ref);
    lua_getfield(L, -1, "transform");
    lua_remove(L, -2);
    // the stack now contains just the transform component
    
    // set the origin
    {
        const btVector3 &origin = transform.getOrigin();
        l_pushvect(L, origin.x(), origin.y(), origin.z());
        lua_setfield(L, -2, "pos");
    }

    // set the rotation
    {
        const btQuaternion &rotation = transform.getRotation();
        l_pushquaternion(
            L, rotation.w(), rotation.x(), rotation.y(), rotation.z());
        lua_setfield(L, -2, "orientation");
    }
}

//// btIDebugDraw Implementation //////////////////////////////////////////////
class DebugDraw : public btIDebugDraw
{
    void drawLine(
        const btVector3& from,
        const btVector3& to,
        const btVector3& color)
    {
        drawLine(from, to, color, color);
    }

    void drawLine(
        const btVector3& from,
        const btVector3& to,
        const btVector3& fromColor,
        const btVector3& toColor)
    {
        glBegin(GL_LINES);
        glColor3d(fromColor.x(), fromColor.y(), fromColor.z());
        glVertex3d(from.x(), from.y(), from.z());
        glColor3d(toColor.x(), toColor.y(), toColor.z());
        glVertex3d(to.x(), to.y(), to.z());
        glEnd();
        glColor3d(1, 1, 1);
    }

    virtual void drawContactPoint(
        const btVector3& PointOnB,
        const btVector3& normalOnB,
        btScalar distance,
        int lifeTime,
        const btVector3& color)
    {
        // do nothing
    }

    virtual void reportErrorWarning(const char* warningString)
    {
        // do nothing
    }

    virtual void draw3dText(const btVector3& location,const char* textString)
    {
        // do nothing
    }
 
    virtual void setDebugMode(int debugMode)
    {
        // do nothing
    }
 
    virtual int getDebugMode() const
    {
        return DBG_DrawWireframe;
    }
};

//// Native Interface /////////////////////////////////////////////////////////
void physics_add_rigid_body(physics_component_s *physics, btRigidBody *body)
{
    physics->world->addRigidBody(body);
}

//// Lua Component ////////////////////////////////////////////////////////////

physics_component_s *get_physics_upvalue(lua_State *L)
{
    return (physics_component_s *)lua_touserdata(L, lua_upvalueindex(1));
}

int physics_draw(lua_State *L)
{
    physics_component_s *physics_component = get_physics_upvalue(L);

    physics_component->world->debugDrawWorld();

    return 0;
}

int physics_update(lua_State *L)
{
    physics_component_s *physics_component = get_physics_upvalue(L);

    physics_component->world->stepSimulation(1/60.0, 10);

    return 0;
}

//int physics_add_rigid_body(lua_State *L)
//{
//    physics_component_s *physics_component = get_physics_upvalue(L);
//
//    btMotionState *motion_state =
//        new MotionState(L, lua_ref(L, LUA_REGISTRYINDEX));
//
//    btCollisionShape *shape = new btBoxShape(btVector3(0.1, 0.1, 0.1));
//    btScalar mass = 1;
//    btVector3 inertia(0, 0, 0);
//    shape->calculateLocalInertia(mass, inertia);
//    btRigidBody::btRigidBodyConstructionInfo rigid_body_ci(
//        mass, motion_state, shape, inertia);
//    btRigidBody* rigid_body = new btRigidBody(rigid_body_ci);
//
//    physics_component->world->addRigidBody(rigid_body);
//
//    return 0;
//}

int physics_get_udata(lua_State *L)
{
    lua_pushvalue(L, lua_upvalueindex(1));
    return 1;
}

// registers a function with the top stack element as an upvalue
// the function is registered in the current function environment
//
// leaves the upvalue element on the stack
static void register_closure(
    lua_State *L,
    const char *name,
    lua_CFunction f)
{
    lua_pushvalue(L, -1);
    lua_pushcclosure(L, f, 1);
    lua_setfield(L, LUA_ENVIRONINDEX, name);
}

int luaopen_dokidoki_physics(lua_State *L)
{
    physics_component_s *physics_component =
        (physics_component_s *)lua_newuserdata(L, sizeof(physics_component_s));

    register_closure(L, "draw", physics_draw);
    register_closure(L, "update", physics_update);
    //register_closure(L, "add_rigid_body", physics_add_rigid_body);
    register_closure(L, "get_udata", physics_get_udata);

    physics_component->broadphase = new btDbvtBroadphase();
    physics_component->collision_configuration =
        new btDefaultCollisionConfiguration();
    physics_component->collision_dispatcher =
        new btCollisionDispatcher(physics_component->collision_configuration);
    physics_component->constraint_solver =
        new btSequentialImpulseConstraintSolver();
    physics_component->world = new btDiscreteDynamicsWorld(
        physics_component->collision_dispatcher,
        physics_component->broadphase,
        physics_component->constraint_solver,
        physics_component->collision_configuration);
    physics_component->world->setGravity(btVector3(0, -10, 0));

    physics_component->world->setDebugDrawer(new DebugDraw());

    // ground
    btCollisionShape *ground_shape =
        new btStaticPlaneShape(btVector3(0, 1, 0), 0);
    btDefaultMotionState *ground_motion_state = new btDefaultMotionState(
        btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 0, 0)));
    btRigidBody::btRigidBodyConstructionInfo ground_rigid_body_ci(
        0, ground_motion_state, ground_shape, btVector3(0, 0, 0));
    btRigidBody *ground_rigid_body = new btRigidBody(ground_rigid_body_ci);
    physics_component->world->addRigidBody(ground_rigid_body);

    return 0;
}
