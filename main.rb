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
    self.keys.each do |planedDate|
      plans = $planFileObj[planedDate]
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
    $planFileObj.keys.sort.each do |planedDate|
      puts
      puts 'Your Plans for ' + planedDate
      numOfPlans = 0
      plans = $planFileObj[planedDate]
      plans.each do |plan|
        numOfPlans = numOfPlans + 1
        printf("%d: \nDetail: %s\nLocation: %s\nCompanions: %s\nImportant: %s\nCreated Time: %d-%d-%d\n",
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
    puts 'which year do you want to make a plan?(2016-3000)'
    yearToPlan=gets.chomp.strip
    if yearToPlan!=yearToPlan.to_i.to_s
      puts 'Input an integer!'
      return
    end
    if yearToPlan.to_i > 3000 || yearToPlan.to_i < 2016
      puts 'Ensure the range of year 2016-3000'
      return
    end
    puts 'which month?(1-12)'
    monthToPlan=gets.chomp.strip
    if monthToPlan!=monthToPlan.to_i.to_s
      puts 'Input an integer!'
      return
    end
    if monthToPlan.to_i < 1 || monthToPlan.to_i > 12
      puts 'Ensure the range of month 1-12'
      return
    end
    puts 'What day?'
    dayToPlan=gets.chomp.strip
    if dayToPlan!=dayToPlan.to_i.to_s||dayToPlan.to_i < 1
      puts 'Please input a positive integer!'
      return
    end
    daysOfMonthC=[31,28,31,30,31,30,31,31,30,31,30,31]
    daysOfMonthL=[31,29,31,30,31,30,31,31,30,31,30,31]
    if yearToPlan.to_i%4==0
      if dayToPlan.to_i > daysOfMonthL[monthToPlan.to_i-1]
        print(yearToPlan,'-',monthToPlan,' does not have ',dayToPlan,' days.')
        return
      end
    else
      if dayToPlan.to_i > daysOfMonthC[monthToPlan.to_i-1]
        print(yearToPlan,'-',monthToPlan,' does not have ',dayToPlan,' days.')
        return
      end
    end
    planEntry.year = yearToPlan.to_i
    planEntry.month = monthToPlan.to_i
    planEntry.day = dayToPlan.to_i

    createdYear = Time.now.year.to_s
    createdMonth = Time.now.month.to_s
    createdDay = Time.now.day.to_s
    createdTime = [createdYear, createdMonth, createdDay].join '-'
    createdCmp = createdYear.to_i*10000+createdMonth.to_i*100+createdDay.to_i

    planedYear = planEntry.year.to_s
    planedMonth = planEntry.month.to_s
    planedDay = planEntry.day.to_s
    planedTime = [planedYear, planedMonth, planedDay].join '-'
    planedCmp = planedYear.to_i*10000+planedMonth.to_i*100+planedDay.to_i
    if planedCmp < createdCmp
      puts 'You are not making a plan for yesterday or earlier days'
    return
    end
    puts 'Fine. You made a plan successfully.'
    printf("Finally, you have made a plan for %d-%d-%d\n",planEntry.year, planEntry.month, planEntry.day)
    printf("Detail: %s\nLocation: %s\nWith: %s\n", planEntry.detail, planEntry.location, planEntry.companions.join(' and '))
    puts 'Are you sure for this plan? (y for yes, otherwise for no)'
    if STDIN.getch == 'y'
      planObj = {"detail": planEntry.detail, "location": planEntry.location, "companions": planEntry.companions,
                 "important": planEntry.important, "targetTime": {
              "year": Time.now.year, "month": Time.now.month,
              "day": Time.now.day, "hour": Time.now.hour
          }
      }
      $planFileObj[planedTime] = [] unless $planFileObj.has_key?(planedTime)
      standardJSON = planObj.to_json
      planObj = JSON.parse standardJSON
      $planFileObj[planedTime].push planObj
      puts 'Congratulations! You\'ve got a new plan!'
      $modifiedFlag = true
    else
      puts 'Cancelled'
    end
    puts $planFileObj
  end

  def tryToDelete(numOfItem,dateToDelete)
      if !$planFileObj[dateToDelete]
        puts 'There\'s no plan for this day, failed to delete!'
      else
        if $planFileObj[dateToDelete].delete_at(numOfItem.to_i-1)
          print("A plan for ",dateToDelete," has been deleted!\n")
          $modifiedFlag=true
        else
          print("Plan item not found!\n")
        end
        if $planFileObj[dateToDelete].empty?
          $planFileObj.delete(dateToDelete)
        end
      end
  end

  def removeAPlan
    puts 'These are all the plans that you made'
    showAll
    puts 'The plans of which year do you want to remove?(2016-3000)'
    yearToDel=gets.chomp.strip
    if yearToDel!=yearToDel.to_i.to_s
      puts 'Input an integer!'
      return
    end
    if yearToDel.to_i > 3000 || yearToDel.to_i < 2016
      puts 'Ensure the range of year 2016-3000'
      return
    end
    puts 'which month?(1-12)'
    monthToDel=gets.chomp.strip
    if monthToDel!=monthToDel.to_i.to_s
      puts 'Input an integer!'
      return
    end
    if monthToDel.to_i < 1 || monthToDel.to_i > 12
      puts 'Ensure the range of month 1-12'
      return
    end
    puts 'What day?'
    dayToDel=gets.chomp.strip
    if dayToDel!=dayToDel.to_i.to_s||dayToDel.to_i < 1
      puts 'Please input a positive integer!'
      return
    end
    daysOfMonthC=[31,28,31,30,31,30,31,31,30,31,30,31]
    daysOfMonthL=[31,29,31,30,31,30,31,31,30,31,30,31]
    if yearToDel.to_i%4==0
      if dayToDel.to_i > daysOfMonthL[monthToDel.to_i-1]
        print(yearToDel,'-',monthToDel,' does not have ',dayToDel,' days.')
        return
      end
    else
      if dayToDel.to_i > daysOfMonthC[monthToDel.to_i-1]
        print(yearToDel,'-',monthToDel,' does not have ',dayToDel,' days.')
        return
      end
    end
    dateToDel=[yearToDel,monthToDel,dayToDel].join '-'
    puts 'So which ones you are going to remove?'
    puts 'Please write down corresponding #\'s of them, using comma to seperate the items'
    numOfPl=gets.chomp.strip

    numOfPl.split(/,|，/).each do |elem|
      if !elem.is_number?
        puts "Numbers required"
        return
      end
    end

    numOfPl.split(/,|，/).uniq.sort.reverse.each do |toDeleteNum|
      tryToDelete(toDeleteNum.strip.chomp, dateToDel)
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