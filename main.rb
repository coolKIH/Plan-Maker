require 'rubygems'
require 'json'
require 'pp'
require 'io/console'
require './plan_entry.rb'

#const values
$WELCOME_MESSAGE = 'Welcome to My-Very-Day!'
$DECISIONS_PROMPT = "Do you like to set a plan \nfor today(y) or another day(n)?"
$FIRST_TIME_WORDS = "It seems like it is your first time here. Let's get started!"

$skippableMsg = '(Enter empty to skip and load a default value)'
$planFileObj = {}


$menuItems = ['Make a Plan', 'Remove a Plan', 'Show All Plans Till Now', 'Exit']

$FILE_PATH = './data.json'

$modifiedFlag = false

#function definitions
def validJson?(json)
  begin
    JSON.parse json
    return true
  rescue JSON::ParserError => e
    return false
  end
end

class Object
  def is_number?
    self.to_f.to_s == self.to_s || self.to_i.to_s == self.to_s
  end
end
class Hash
  def getPlanSize
    size = 0
    self.keys.each do |createdDate|
      plans = $planFileObj[createdDate]
      plans.each do |plan|
        size = size + 1
      end
    end
    size
  end
end

def saveChangesToFile
  printChDelay 'Saving...'
  File.open($FILE_PATH, 'w') do |aFile|
    aFile.puts $planFileObj.to_json
  end
end


def showAll
  puts 'There are totalling ' + $planFileObj.getPlanSize.to_s + ' items of plans'
  $planFileObj.keys.each do |createdDate|
    puts
    puts 'Your Plans for ' + createdDate
    numOfPlans = 0
    plans = $planFileObj[createdDate]
    plans.each do |plan|
      numOfPlans = numOfPlans + 1
      printf("%d: \nDetail: %s\nLocation: %s\nCompanions: %s\nImportant: %s\nPlan Time: %d-%d-%d\n",
        numOfPlans, plan['detail'], plan['location'], plan['companions'].join(', '), plan['important']?'yes':'no',
        plan['targetTime']['year'],plan['targetTime']['month'], plan['targetTime']['day'] )
    end
  end
end
def makeAPlan
  planEntry = PlanEntry.new
  printChDelay 'Start planning...'
  puts 'Please illustrate your plan: what to do?'
  detail = gets.chomp.strip
  while detail == ''
    puts 'Please make sure this field is not empty'
    detail = gets.chomp.strip
  end
  planEntry.detail = detail
  puts 'Where do you want the event to take place? ' + $skippableMsg
  planEntry.location = gets.chomp.strip
  puts 'Who is/are going to do that with you? (comma to split)' + $skippableMsg
  companions = gets.chomp.strip
  planEntry.companions = companions.split(/, | ，/)
  puts 'Important or not? (y for yes, otherwise for no) ' + $skippableMsg
  ipt = STDIN.getch
  if ipt == 'y'
    planEntry.important = true
  end
  puts 'Take your time for the plan. How many days from now will it happen? (0 for today) ' + $skippableMsg
  while daysFromNow = gets.chomp.strip
    if daysFromNow == ''
      break
    elsif daysFromNow.is_number?
      daysFromNow = daysFromNow.to_i
      if daysFromNow < 0
        puts 'Input again. You are not making a plan for yesterday or earlier days'
      else
        now = Time.now
        future = now + 24 * 60 * 60 * daysFromNow
        planEntry.year = future.year.to_i
        planEntry.month = future.month.to_i
        planEntry.day = future.day.to_i
        planEntry.hour = future.hour.to_i
        puts 'Fine. You made a plan successfully.'
        break
      end
    else
      puts 'Please input a valid number'
    end
  end
  printf("Finally, you have made a plan for %d-%d-%d\n",planEntry.year, planEntry.month, planEntry.day)
  printf("Detail: %s\nLocation: %s\nWith: %s\n", planEntry.detail, planEntry.location, planEntry.companions.join(' and '))
  puts 'Are you sure for this plan? (y for yes, otherwise for no)'
  if STDIN.getch == 'y'
    planObj = {"detail": planEntry.detail, "location": planEntry.location, "companions": planEntry.companions,
               "important": planEntry.important, "targetTime": {
            "year": planEntry.year, "month": planEntry.month,
            "day": planEntry.day, "hour": planEntry.hour
        }}
    createdYear = Time.now.year.to_s
    createdMonth = Time.now.month.to_s
    createdDay = Time.now.day.to_s
    createdTime = [createdYear, createdMonth, createdDay].join '-'
    $planFileObj[createdTime] = [] unless $planFileObj.has_key?(createdTime)
    standardJSON = planObj.to_json
    planObj = JSON.parse standardJSON
    $planFileObj[createdTime].push planObj
    puts 'Congratulations! You\'ve got a new plan!'
    $modifiedFlag = true
  else
    puts 'Cancelled'
  end
  puts $planFileObj
end

def tryToDelete numOfitem

end
def removeAPlan
  puts 'These are all the plans that you made'
  showAll
  puts 'So which ones you are going to remove?'
  puts 'Please write down corresponding #\'s of them, using comma to seperate the items'
  puts 'Enter "quit" to leave here'
  #Continue here to make changes to the $planFileObj
  while userInput = gets.chomp.strip.downcase
    if userInput == 'quit'
      break
      elsif userInput.split(',').each do |toDeleteNum|
        tryToDelete toDeleteNum.strip
      end
    end
  end
end
def displayMenu
  puts
  itemNum = 1;
  $menuItems.each do |item|
    puts itemNum.to_s + '. ' + item
    itemNum = itemNum + 1
  end
  puts
end
def printChDelay(str, t=0.01)
  str.each_char do |ch|
    sleep t
    print ch
  end
  puts
end
def getUserInput
    displayMenu
    userInput = STDIN.getch
    if userInput=='1'
      makeAPlan
      getUserInput
    elsif userInput=='2'
      removeAPlan
      getUserInput
    elsif userInput=='3'
      showAll
    elsif userInput=='4'
      if $modifiedFlag
        puts 'You\'ve modified your plans. Do you want to save the changes? (enter y for yes or n for no)'
        if( STDIN.getch == 'y' )
          saveChangesToFile
        else
          puts 'You will lose all the changes if you insist. Enter y if you really do or otherwise save them'
          if STDIN.getch != 'y'
            saveChangesToFile
          end
        end
      end
      exit 1
    else
      printChDelay 'Please input a valid number'
    end
    getUserInput
end

#program starting points
printChDelay $WELCOME_MESSAGE

if File::exists?($FILE_PATH)
  planStr = File.read($FILE_PATH)
  if validJson?planStr
  $planFileObj = JSON.parse(planStr)
  else
    puts 'Currently the file for your plan data is not valid json file.
    Later the file may be overwritten, but I will back it up for you right now.'
    FileUtils.copy Pathname, Pathname + '.backup'
  end

else
  printChDelay $FIRST_TIME_WORDS
end

getUserInput