# A broken pattern

The module pattern used in singleton.lua is an example of what doesn't work.
When we run `lua main.lua`, the following error occurs:

    lua: ./singleton.lua:4: attempt to call global 'say_hi' (a nil value)
    stack traceback:
        ./singleton.lua:4: in function 'f'
        main.lua:3: in main chunk
        [C]: ?

