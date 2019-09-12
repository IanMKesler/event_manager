require "csv"
require "google/apis/civicinfo_v2"
require "erb"

# def clean_zipcode(zipcode)
#   return "00000" if !zipcode  #can change to an empty string with nil.to_s => ""
#   case 
#   when zipcode.length == 5 #In either other case doesn't change zipcode when length == 5, delete
#     return zipcode
#   when zipcode.length < 5 
#     return zipcode.rjust 5, "0" 
#   when zipcode.length > 5 #Can combine these last two for same effect 
#     return zipcode[0..4]
#   end
# end

### Refactoring above

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(number)
  number_split = number.split("").select {|x| x.match(/[0-9]/)}
  case
  when number_split.length < 10 || (number_split.length == 11 && number_split[0] != 1) || number_split.length >= 11
    return false
  when number_split.length == 10
    return format_phone_number(number_split)
  when number_split.length == 11 && number_split[0] == 1
    return format_phone_number(number_split[1..-1])
  end
end

def format_phone_number(number_split)
  return (number_split[0..2] + ["-"] + number_split[3..5] + ["-"] + number_split[6..-1]).join("")
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    legislators = civic_info.representative_info_by_address(
          address: zipcode,
          levels: "country",
          roles: ["legislatorUpperBody", "legislatorLowerBody"]
      ).officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letters(id, form_letter)
  Dir.mkdir("output") unless Dir.exists? "output"
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') { |file| file.puts form_letter}
end


puts "EventManager Initialized!"
if File.exist? "event_attendees.csv"
  contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol
  template_letter = File.read "form_letter.erb"
  erb_template = ERB.new template_letter

  contents.each { |row|
    id = row[0]
    name = row[:first_name]
    phone = clean_phone_number(row[:homephone])

    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)

    

    form_letter = erb_template.result(binding)
    save_thank_you_letters(id, form_letter)
    #puts form_letter
  }
end


