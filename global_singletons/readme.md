# Global singletons in lua

The purpose of this directory is to find a reusable
code pattern for lua modules meant to be used as
global singletons.

Specifically, they may be included from different places,
but there should still only exist a single, global copy
of data shared by the module's interface.

Directory 1 contains my first attempt along with a
minimal reproduction of why it does not work.
