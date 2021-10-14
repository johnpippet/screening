def tweak_booking_codes():
    global input_ws
    global starting_row
    global ending_row
    global booking_number_column
    global activity_id_column
 
    project_code = ""
    found = 0
    current_row = starting_row + 1
    while current_row <= ending_row:
        progress = ((current_row - starting_row) * 100) / (ending_row - starting_row)
        sys.stdout.write("%d%%   \r" % progress)
        sys.stdout.flush()
 
        cell = input_ws.cell(row=current_row, column=activity_id_column)
 
        if cell.value is not None:
            split_text = str(cell.value).strip().rsplit("_")
            if len(split_text) >= 2:
                project_code = split_text[0].strip()
                if len(project_code) >= 5:
                    if project_code.isdigit():
                        answer = "Y"
                    else:
                        answer = str(raw_input("Is '" + project_code + "' the project code? (Y/N)")).upper().strip()
                    if answer == "Y":
                        found = 1
                        current_row = ending_row
 
            split_text = str(cell.value).strip().rsplit("-")
            if len(split_text) >= 2:
                project_code = split_text[0].strip()
                if len(project_code) >= 5:
                    if project_code.isdigit():
                        answer = "Y"
                    else:
                        answer = str(raw_input("Is '" + project_code + "' the project code? (Y/N)")).upper().strip()
                    if answer == "Y":
                        found = 1
                        current_row = ending_row
 
        current_row = current_row + 1
 
    if found == 0:
        ERROR("Unable to find project code, skipping booking number reformatting")
        return
 
    current_row = starting_row + 1
    while current_row <= ending_row:
        progress = ((current_row - starting_row) * 100) / (ending_row - starting_row)
        sys.stdout.write("%d%%   \r" % progress)
        sys.stdout.flush()
 
        cell = input_ws.cell(row=current_row, column=booking_number_column)
 
        if cell.value is not None:
            sub_code = str(cell.value).strip().zfill(6)
            cell.value = project_code + '_' + sub_code
        else:
            WARNING(": has no sub booking code", current_row)
            cell.value = project_code
 
        current_row = current_row + 1
 
    return
 
try:
    tweak_booking_codes()
 
except ValueError as error:
    print('Caught this Exception: ' + str(error))
    print('Cannot Continue, stopping')
except:
    print "Unexpected error: ", sys.exc_info()[0]
    print('Cannot Continue, stopping')
    raise
