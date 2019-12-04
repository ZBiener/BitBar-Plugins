# BitBar Plugins

This repository contains two plugins for [BitBar](https://getbitbar.com/).

## OmniTasks4BitBar.py

The plugin displays tasks from Omnifocus, divided into categories, sorted by date. Default categories are Past due, Now (within 2 days), Soon (within a month), and Home. They can be modified. Colors can be assigned to each category. It uses a combination of Python and AppleScript. There's a script version for Omnifocus 2 and for Omnifocus 3.

[[ https://github.com/ZBiener/BitBar-Plugins/blob/master/images/OFT-dropdown.jpg | width=100px ]] 

**Click** on a task in the dropdown menu to open it in Omnifocus, with its note expanded (it is has one). 

**Option+click** to mark a task complete. 

Tasks from Omnifocus can be filtered to exclude projects and contexts by supplying extra conditions in the 'load_task_list()' function. Sample conditions are included inside the function.

Colors and main display categories can be modified through the 'categoryDefinitions' list of lists. An arbitrary number of categories is allowed. Each category is defined as a list of these 7 properties: 

1) Name                   	- the text displayed
2) Rank in display order  	- lower number means displayed higher in the dropdown menu or 
							more to the left in the menubar
3) Rank in evaluation order - each task can only belong to a single category. A lower number 
                           	means the category condition (item 7) will be evaluated earlier, and so 
                           	will capture tasks firsts. Tasks that are captured will be 
                           	excluded from appearing in any other category.
4) color                  	- display color in dropdown menu
5) color in dark more     	- display color in dropdown menu, in dark mode
							(This is probably no longer necessary, but I haven't confirmed)
6) color code in ANSI     	- colors in the menubar itself require ANSI codes. They will not take 
							color names. Enter the ANSI codes here.
7) condition              	- the condition defines inclusion in the category, in python code. 
                            conditions can access the following task properties: 
                            task.name, task.duedate, task.project, task.tag.
                            See script for examples.

