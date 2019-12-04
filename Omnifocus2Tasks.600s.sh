#!/usr/bin/env PYTHONIOENCODING=UTF-8 /usr/local/bin/python3

# <bitbar.title>OmnifTasks4BitBar</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Zvi Biener</bitbar.author>
# <bitbar.author.github>ZBiener</bitbar.author.github>
# <bitbar.desc>Displays tasks from Omnifocus, divided into categories, sorted by date. Categories are Past due, Now (within 2 days), and Soon (within a month). Can be modified. Colors can be assigned to each category, both on the menubar and dropdown menu. Dropdown menu allow to open the task (with it's note automatically expanded) or, using the option key, to mark it completed. Tasks from Omnifocus can also be filtered to exclude certain projects, tags, etc. See get_task_list_as_string(). </bitbar.desc>
# <bitbar.image></bitbar.image>
# <bitbar.dependencies>python</bitbar.dependencies>
# <bitbar.abouturl></bitbar.abouturl>


# The plugin displays tasks from Omnifocus 2, divided into categories, sorted by date. Default categories are Past due, Now (within 2 days), Soon (within a month), and Home. They can be modified. Colors can be assigned to each category. It uses a combination of Python and AppleScript.
# 
# **Click** on a task in the dropdown menu to open it in Omnifocus, with its note expanded (it is has one). 
# 
# **Option+click** to mark a task complete. 
# 
# Tasks from Omnifocus can be filtered to exclude projects and contexts by supplying extra conditions in the 'load_task_list()' function. Sample conditions are included inside the function.
# 
# Colors and main display categories can be modified through the 'categoryDefinitions' list of lists. An arbitrary number of categories is allowed. Each category is defined as a list of these 7 properties: 
# 
# 1) Name                     - the text displayed
# 2) Rank in display order    - lower number means displayed higher in the dropdown menu or 
#                             more to the left in the menubar
# 3) Rank in evaluation order - each task can only belong to a single category. A lower number 
#                             means the category condition (item 7) will be evaluated earlier, and so 
#                             will capture tasks firsts. Tasks that are captured will be 
#                             excluded from appearing in any other category.
# 4) color                    - display color in dropdown menu
# 5) color in dark more       - display color in dropdown menu, in dark mode
#                             (This is probably no longer necessary, but I haven't confirmed)
# 6) color code in ANSI       - colors in the menubar itself require ANSI codes. They will not take 
#                             color names. Enter the ANSI codes here.
# 7) condition                - the condition defines inclusion in the category, in python code. 
#                             conditions can access the following task properties: 
#                             task.name, task.duedate, task.project, task.tag.
#                             See script for examples.
# 


import sys
import applescript
from datetime import datetime, timedelta


categoryDefinitions = [
['Past',    1, 2, 'red',    'red',      '\x1b[31m', 'task.duedate < datetime.now()'],
['Now',     2, 3, 'black',  'white',    '\x1b[0m',  'task.duedate > datetime.now() and task.duedate <= (datetime.now() + timedelta(days=2))'],
['Soon',    3, 4, 'black',  'white',    '\x1b[0m',  'task.duedate > (datetime.now() + timedelta(days=2)) and task.duedate <= (datetime.now() + timedelta(days=32))'],
['Home',    4, 1, 'black',  'white',    '\x1b[0m',  '(task.project == "Home" or task.context == "home") and task.duedate <= (datetime.now() + timedelta(days=32))'],
]

# Some other variables
#
pastDueColor="red"      # Past due actions are *always* in this color, no matter what category they
                        # belong to. If you don't want them colored in a special way, make this an
                        # empty string 
colorAnsiReset=""       # Controls the color of commas in the menubar display. Empty string means commas  
                        # takethe color of the category that preceeds them.
bitbarSeparatorLine="\n---" # required for bitbar
     

###############################################################################
#
class tasks:
    # Using a class (as opposed to dictionaries, etc.) isn't really needed for 
    # this script. However, a class is constructed here to allow various 
    # expansions of the script in the future.
    def __init__(self, taskID, taskName, dueDate, project, context):
        self.taskID = taskID
        self.name = taskName
        self.duedate = dueDate
        self.project = project
        self.context = context
        
    def bibarOutput(self, color):
        if pastDueColor != "" and self.duedate < datetime.now():
            color = pastDueColor
        # Modify below to include any task properties you want to display
        fixedParams=\
            " | color=" + color + " \
            bash=\"" + sys.argv[0] + "\" \
            param2=\"" + self.taskID + "\" \
            refresh=true terminal=false  "            
        firstLine=\
            self.duedate.strftime("%b %d") + "\t" + self.name + \
            fixedParams + \
            "param1=open"            
        secondLine=\
            "Done" + "\t" + self.name + \
            fixedParams + \
            "param1=done " + \
            "alternate=true "                              
        return (firstLine + "\n" + secondLine)

class category:
    # Using a class (as opposed to dictionaries, etc.) isn't really needed for 
    # this script. However, a class is constructed here to allow various 
    # expansions of the script in the future.
    categoryList = []
    
    def __init__(self, Name, display_rank, eval_rank, color, colorDarkMode, colorAnsi, condition):
        self.name = Name
        self.display_rank = display_rank
        self.eval_rank = eval_rank
        self.color = color
        self.colorDarkMode = colorDarkMode
        self.colorAnsi = colorAnsi
        self.condition = condition
        self.tasks = []            
            
    def doesTaskBelong(self, task):
        if eval(self.condition):
            self.tasks.append(task)
            return True
        else:
            return False
                 
def dark_state():
    state_scrpt=applescript.AppleScript('''
        tell application "System Events" to tell appearance preferences
        	get properties
        	set currentValue to dark mode
        		return currentValue
        end tell
    ''')
    return state_scrpt.run()
 
def mark_task_completed(taskID) :
    mark_task_completed_scpt = applescript.AppleScript('''
        on run taskID
        	tell application "OmniFocus"
        		tell default document
        			if (count (every remaining task of every flattened context)) > 0 then
        				repeat with aTask in (every remaining task of every flattened context)
        					if id of aTask as string is equal to taskID as string then
        						mark complete aTask
        						return
        					end if
        				end repeat	
        			end if
        		end tell
        	end tell
        end run 
    ''')
    mark_task_completed_scpt.run(taskID)
    
def open_task(taskID):
    open_task_scpt = applescript.AppleScript('''
    on run taskID
    tell application "OmniFocus"
    	tell default document
    		set MyTask to task id taskID -- or whatever you've done to get MyTask
    		set MyTaskURL to ("omnifocus:///task/" & (id of MyTask))
    		tell (make new document window)
    			GetURL MyTaskURL
    			activate "OmniFocus"                                    
    		end tell
    	end tell

        tell content of front window
        		repeat with lineItem in descendant trees
        			set isSelected to selected of lineItem
        			if isSelected then
        				set note expanded of lineItem to true
        			end if
        		end repeat
        end tell
            
    end tell
    end run
    ''')
    open_task_scpt.run(taskID)
        
def load_category_list(parameterList):
    categoryList=[]
    for item in parameterList:
        newCatObject=category(*item)
        if dark_state(): 
            newCatObject.color=newCatObject.colorDarkMode
        categoryList.append(newCatObject)
    return categoryList

def load_task_list():
    getTasksScpt = applescript.AppleScript('''
    set AllTasks to ""
    set the_list to {}
    tell application "OmniFocus"
    	tell default document
    		if (count (every remaining task of every flattened context)) > 0 then
    			repeat with aTask in (every remaining task of every flattened context)
    				if number of tasks of aTask is 0 and due date of aTask is not missing value then
    					-- SPECIFY ANY LIMITING CONDITIONS YOU WANT
    					if the name of the context of aTask is not "XXXX" then	
    						set end of the_list to {\
                                id of aTask, \
                                name of aTask as string, \
                                due date of aTask, \
                                name of containing project of aTask as string, \
                                name of context of aTask}
    					end if
    				end if
    			end repeat
			
    		end if
    	end tell
    end tell
    the_list
    ''')
    taskList=[]
    for item in getTasksScpt.run():  
        task=tasks(*item)
        taskList.append(task) 
    return taskList
    
def parse_tasks_by_category(taskList, categoryList):

    taskList.sort(key=lambda x: x.duedate)
    categoryList.sort(key=lambda x: x.eval_rank)
    
    for task in taskList:  
        for cat in categoryList:
            if cat.doesTaskBelong(task):
                break
    return categoryList   
    
def contruct_menubar_text(tasksByCategory):
    # A dictionary for the menubar text is an easy way to determine how many commas 
    # to display. See the condition in the join.format command.
    tasksByCategory.sort(key=lambda x: x.display_rank)    
    menubarTextDict={}
    for i in range(3): 
        menubarTextDict.update({tasksByCategory[i].colorAnsi + \
                                tasksByCategory[i].name: len(tasksByCategory[i].tasks)})
        
        menubarLine=(f"{colorAnsiReset}, ".join("{}: {}".format(k, v) for k, v in menubarTextDict.items() if v != 0))
        
    return (menubarLine + bitbarSeparatorLine)
    
def construct_dropdown_text(tasksByCategory):
    dropdownText=[] 
    for cat in tasksByCategory:
        if len(cat.tasks) != 0:
            dropdownText.append(cat.name+":")
        for taskObj in cat.tasks: 
            dropdownText.append(taskObj.bibarOutput(cat.color))
        dropdownText.append(bitbarSeparatorLine)
            
    output=("\n".join(f"{x}" for x in dropdownText))
    return output    


def main():
    if len(sys.argv) > 2:
        if sys.argv[1] == "done":
            mark_task_completed(sys.argv[2])
        if sys.argv[1] == "open":
            open_task(sys.argv[2]) 
            
    categoryList=load_category_list(categoryDefinitions)
    taskList=load_task_list()
    tasksByCategory=parse_tasks_by_category(taskList,categoryList)
    menubarText=contruct_menubar_text(tasksByCategory)
    dropdownText=construct_dropdown_text(tasksByCategory)
    
    print(menubarText)
    print(dropdownText)    
     
main()
