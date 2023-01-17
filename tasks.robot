*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Desktop
Library             RPA.Archive


*** Variables ***
${URL}=         https://robotsparebinindustries.com/#/robot-order
${orderUrl}=    https://robotsparebinindustries.com/orders.csv


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Log    ${row}[Order number]
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}
        ${screenshot}=    Take a screenshot of the robot    ${row}
        Embed the robot screenshot to the receipt PDF file    ${row}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close the browser


*** Keywords ***
Open the robot order website
    Open Available Browser    ${URL}
    Maximize Browser Window

Get orders
    Download    ${orderUrl}    overwrite=true
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}

Close the annoying modal
    Wait Until Page Contains Element    css:.btn-dark
    Click Button    css:.btn-dark

Fill the form
    [Arguments]    ${row}
    Select From List By Index    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath://div[@id='root']/div/div/div/div/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    preview
    Wait Until Element Is Visible    robot-preview-image

Submit the order
    Click Button    order
    Run Keyword And Ignore Error    Submit the order

Store the receipt as a PDF file
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf}=    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}${row}[Order number].pdf    overwrite=true
    RETURN    ${pdf}

Take a screenshot of the robot
    [Arguments]    ${row}
    ${screenshot}=    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}${row}[Order number].png
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${row}
    Add Watermark Image To Pdf
    ...    ${OUTPUT_DIR}${/}${row}[Order number].png
    ...    ${OUTPUT_DIR}${/}${row}[Order number].pdf
    ...    ${OUTPUT_DIR}${/}${row}[Order number].pdf

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip    ${OUTPUT_DIR}    ${zip_file_name}

Close the browser
    Close Browser
