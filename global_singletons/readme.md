# Global singletons in lua

The purpose of this directory is to find a reusable
code pattern for lua modules meant to be used as
global singletons.

Specifically, they may be included from different places,
but there should still only exist a single, global copy
of data shared by the module's interface.

Each of the following sections describes sample code in one of the
subdirectories.

## 1. A broken pattern

Directory 1 contains my first attempt along with a
minimal reproduction of why it does not work.

The module pattern used in singleton.lua is an example of what doesn't work.
When we run `lua main.lua`, the following error occurs:

    lua: ./singleton.lua:4: attempt to call global 'say_hi' (a nil value)
    stack traceback:
        ./singleton.lua:4: in function 'f'
        main.lua:3: in main chunk
        [C]: ?

## 2. A working pattern

It looks like simply defining the say_hi function before the definition of
M.f seems to fix the problem I saw in the first case. However, I suspect
this solution would break if we used dofile instead of require. I'm interested
in a pattern that will also work for dofile-style file includes.

## 3. Number 2 breaks with dofile

This is basically the same as pattern 2, except that calls to require have
been replaced by dofile.

The output produced is:

    singleton is running
    hi! x=5
    singleton is running
    hi! x=3

Since we'd like there to be a single global instance of the module's data,
we really want the last line to give x=5.

## 4. A more robust pattern

This pattern uses a single overall global to ensure each singleton is always a
singleton. It avoids executing the module more than once. Here is a general
template for the pattern:

    --[[ Singleton header pattern ]]

    local selfname = debug.getinfo(1).source
    if not global_singleton then global_singleton = {} end
    if global_singleton[selfname] then return global_singleton[selfname] end
    local M = {}
    global_singleton[selfname] = M

    --[[ Begin module definition ]]

    -- << Define local (=private) variables and functions first. >>

    local function say_hi() print('hi! x=' .. M.x) end

    -- << Next, define public variables and funcions. >>

    M.x = 3

    M.f = function() say_hi() end

    --[[ End module definition ]]

    return M
