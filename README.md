# Pico-8 Project Template

#### To run this project
- Clone repo
- run `make output`
- open `output.p8` in pico-8

## About

This is an empty Pico-8 project template but with scripts allowing you to separate graphics, music and code and also split the code into multiple files while working on your project.

It comes with a Makefile and a python-script which parses a source-file and allows inclusion of other source-files from it.

When you 'make' your project the graphics and sounds are taken from the file gfxsfx.p8 but no code is picked up from that file so the code-section in that cart can be used to prototype graphics, music and other things.

To include another source-file from the main-source file just type "include *filename*" and if the file exists it will be concatinated into the source, see source.lua for an example.

The parse.py-script can optimize the output to remove comments and indentation to save characters. Just add the argument --optimize after the filename. To get this behaviour when you make the project, edit the Makefile to say: PARSEOPTIONS=--optimize

For now it's not possible to include files from within a file that is getting included, perhaps this will be added in the future.

### Graphics and Sound
**Remember to paste your output.p8 graphics and sound section over the text in `gfxsfx.p8` or your changes will be overwritten!**