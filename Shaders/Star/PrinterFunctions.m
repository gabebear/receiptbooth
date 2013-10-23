//
//  PrinterFunctions.m
//  IOS_SDK
//
//  Created by Tzvi on 8/2/11.
//  Copyright 2011 - 2013 STAR MICRONICS CO., LTD. All rights reserved.
//

#import "PrinterFunctions.h"
#import "StarIO/SMPort.h"
#import "RasterDocument.h"
#import "StarBitmap.h"
#import <sys/time.h>
#include <unistd.h>

@implementation PrinterFunctions

#pragma mark Open Cash Drawer

/**
 * This function opens the cashdraw connected to the printer
 * This function just send the byte 0x07 to the printer which is the open cashdrawer command
 * portName - Port name to use for communication. This should be (TCP:<IPAddress>)
 * portSettings - Should be blank
 */
+ (void)OpenCashDrawerWithPortname:(NSString *)portName portSettings:(NSString *)portSettings
{
    unsigned char opencashdrawer_command[] = {0x07};
    NSData *commands = [[NSData alloc] initWithBytes:opencashdrawer_command length:sizeof(opencashdrawer_command)];
    
    [self sendCommand:commands portName:portName portSettings:portSettings timeoutMillis:10000];
    
    [commands release];
}

#pragma mark Check Status

/**
 * This function checks the status of the printer.
 * The check status function can be used for both portable and non portable printers.
 * portName - Port name to use for communication. This should be (TCP:<IPAddress>)
 * portSettings - Should be blank
 */
+ (void)CheckStatusWithPortname:(NSString *)portName portSettings:(NSString *)portSettings sensorSetting:(SensorActive)sensorActiveSetting
{
    SMPort *starPort = nil;
    @try
    {
        starPort = [SMPort getPort:portName :portSettings :10000];
        if (starPort == nil)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fail to Open Port" 
                                                            message:@""
                                                           delegate:nil 
                                                  cancelButtonTitle:@"OK" 
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
            return;
        }
        usleep(1000 * 1000);
        
        StarPrinterStatus_2 status;
        [starPort getParsedStatus:&status :2];
        
        NSString *message = @"";
        if (status.offline == SM_TRUE)
        {
            message = @"The printer is offline";
            if (status.coverOpen == SM_TRUE)
            {
                message = [message stringByAppendingString:@"\nCover is Open"];
            }
            else if (status.receiptPaperEmpty == SM_TRUE)
            {
                message = [message stringByAppendingString:@"\nOut of Paper"];
            }
        }
        else
        {
            message = @"The Printer is online";
        }

        NSString *drawerStatus;
        if (sensorActiveSetting == SensorActiveHigh)
        {
            drawerStatus = (status.compulsionSwitch == SM_TRUE) ? @"Open" : @"Close";
            message = [message stringByAppendingFormat:@"\nCash Drawer: %@", drawerStatus];
        }
        else if (sensorActiveSetting == SensorActiveLow)
        {
            drawerStatus = (status.compulsionSwitch == SM_FALSE) ? @"Open" : @"Close";
            message = [message stringByAppendingFormat:@"\nCash Drawer: %@", drawerStatus];
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Printer Status"
                                                        message:message
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    @catch (PortException *exception)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Printer Error" 
                                                        message:@"Get status failed"
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    @finally 
    {
        [SMPort releasePort:starPort];
    }
}

#pragma mark 1D Barcode

/**
 * This function is used to print bar codes in the 39 format
 * context - Activity for displaying messages to the user
 * portName - Port name to use for communication. This should be (TCP:<IPAddress>)
 * portSettings - Should be blank
 * barcodeData - These are the characters that will be printed in the bar code. The characters available for this bar code are listed in section 3-43 (Rev. 1.12). 
 * barcodeDataSize - This is the number of characters in the barcode.  This should be the size of the preceding parameter
 * option - This tell the printer weather put characters under the printed bar code or not.  This may also be used to line feed after the bar code is printed.
 * height - The height of the bar code.  This is measured in pixels
 * width - The Narrow wide width of the bar code.  This value should be between 1 to 9.  See section 3-42 (Rev. 1.12) for more information on the values.
 */
+ (void)PrintCode39WithPortname:(NSString*)portName portSettings:(NSString*)portSettings barcodeData:(unsigned char *)barcodeData barcodeDataSize:(unsigned int)barcodeDataSize barcodeOptions:(BarCodeOptions)option height:(unsigned char)height narrowWide:(NarrowWide)width
{
    unsigned char n1 = 0x34;
    unsigned char n2 = 0;
    switch (option) {
        case No_Added_Characters_With_Line_Feed:
            n2 = 49;
            break;
        case Adds_Characters_With_Line_Feed:
            n2 = 50;
            break;
        case No_Added_Characters_Without_Line_Feed:
            n2 = 51;
            break;
        case Adds_Characters_Without_Line_Feed:
            n2 = 52;
            break;
    }
    unsigned char n3 = 0;
    switch (width)
    {
        case NarrowWide_2_6:
            n3 = 49;
            break;
        case NarrowWide_3_9:
            n3 = 50;
            break;
        case NarrowWide_4_12:
            n3 = 51;
            break;
        case NarrowWide_2_5:
            n3 = 52;
            break;
        case NarrowWide_3_8:
            n3 = 53;
            break;
        case NarrowWide_4_10:
            n3 = 54;
            break;
        case NarrowWide_2_4:
            n3 = 55;
            break;
        case NarrowWide_3_6:
            n3 = 56;
            break;
        case NarrowWide_4_8:
            n3 = 57;
            break;
    }
    unsigned char n4 = height;
    
    unsigned char *command = (unsigned char*)malloc(6 + barcodeDataSize + 1);
    command[0] = 0x1b;
    command[1] = 0x62;
    command[2] = n1;
    command[3] = n2;
    command[4] = n3;
    command[5] = n4;
    for (int index = 0; index < barcodeDataSize; index++)
    {
        command[index + 6] = barcodeData[index];
    }
    command[6 + barcodeDataSize] = 0x1e;
    
    int commandSize = 6 + barcodeDataSize + 1;
    
    NSData *dataToSentToPrinter = [[NSData alloc] initWithBytes:command length:commandSize];
    
    [self sendCommand:dataToSentToPrinter portName:portName portSettings:portSettings timeoutMillis:10000];
    
    [dataToSentToPrinter release];
    free(command);
}

/**
 * This function is used to print bar codes in the 93 format
 * portName - Port name to use for communication. This should be (TCP:<IPAddress>)
 * portSettings - Should be blank
 * barcodeData - These are the characters that will be printed in the bar code. The characters available for this bar code are listed in section 3-43 (Rev. 1.12). 
 * barcodeDataSize - This is the number of characters in the barcode.  This should be the size of the preceding parameter
 * option - This tell the printer weather put characters under the printed bar code or not.  This may also be used to line feed after the bar code is printed.
 * height - The height of the bar code.  This is measured in pixels
 * width - This is the number of dots per module.  This value should be between 1 to 3.  See section 3-42 (Rev. 1.12) for more information on the values.
 */
+ (void)PrintCode93WithPortname:(NSString*)portName portSettings:(NSString*)portSettings barcodeData: (unsigned char *)barcodeData barcodeDataSize:(unsigned int)barcodeDataSize barcodeOptions:(BarCodeOptions)option height:(unsigned char)height min_module_dots:(Min_Mod_Size)width
{
    unsigned char n1 = 0x37;
    unsigned char n2 = 0;
    switch (option)
    {
        case No_Added_Characters_With_Line_Feed:
            n2 = 49;
            break;
        case Adds_Characters_With_Line_Feed:
            n2 = 50;
            break;
        case No_Added_Characters_Without_Line_Feed:
            n2 = 51;
            break;
        case Adds_Characters_Without_Line_Feed:
            n2 = 52;
            break;
    }
    unsigned char n3 = 0;
    switch (width)
    {
        case _2_dots:
            n3 = 49;
            break;
        case _3_dots:
            n3 = 50;
            break;
        case _4_dots:
            n3 = 51;
            break;
    }
    unsigned char n4 = height;
    unsigned char *command = (unsigned char*)malloc(6 + barcodeDataSize + 1);
    command[0] = 0x1b;
    command[1] = 0x62;
    command[2] = n1;
    command[3] = n2;
    command[4] = n3;
    command[5] = n4;
    for (int index = 0; index < barcodeDataSize; index++)
    {
        command[index + 6] = barcodeData[index];
    }
    command[6 + barcodeDataSize] = 0x1e;
    
    int commandSize = 6 + barcodeDataSize + 1;
    
    NSData *dataToSentToPrinter = [[NSData alloc] initWithBytes:command length:commandSize];
    
    [self sendCommand:dataToSentToPrinter portName:portName portSettings:portSettings timeoutMillis:10000];
    
    [dataToSentToPrinter release];
    free(command);
}

/**
 * This function is used to print bar codes in the ITF format
 * portName - Port name to use for communication. This should be (TCP:<IPAddress>)
 * portSettings - Should be blank
 * barcodeData - These are the characters that will be printed in the bar code. The characters available for this bar code are listed in section 3-43 (Rev. 1.12). 
 * barcodeDataSize - This is the number of characters in the barcode.  This should be the size of the preceding parameter
 * option - This tell the printer weather put characters under the printed bar code or not.  This may also be used to line feed after the bar code is printed.
 * height - The height of the bar code.  This is measured in pixels
 * width - This is the number of dots per module.  This value should be between 1 to 3.  See section 3-42 (Rev. 1.12) for more information on the values.
 */
+ (void)PrintCodeITFWithPortname:(NSString*)portName portSettings:(NSString*)portSettings barcodeData:(unsigned char *)barcodeData barcodeDataSize:(unsigned int)barcodeDataSize barcodeOptions:(BarCodeOptions)option height:(unsigned char)height narrowWide:(NarrowWideV2)width
{
    unsigned char n1 = 0x35;
    unsigned char n2 = 0;
    switch (option)
    {
        case No_Added_Characters_With_Line_Feed:
            n2 = 49;
            break;
        case Adds_Characters_With_Line_Feed:
            n2 = 50;
            break;
        case No_Added_Characters_Without_Line_Feed:
            n2 = 51;
            break;
        case Adds_Characters_Without_Line_Feed:
            n2 = 52;
            break;
    }
    unsigned char n3 = 0;
    switch (width)
    {
        case NarrowWideV2_2_5:
            n3 = 49;
            break;
        case NarrowWideV2_4_10:
            n3 = 50;
            break;
        case NarrowWideV2_6_15:
            n3 = 51;
            break;
        case NarrowWideV2_2_4:
            n3 = 52;
            break;
        case NarrowWideV2_4_8:
            n3 = 53;
            break;
        case NarrowWideV2_6_12:
            n3 = 54;
            break;
        case NarrowWideV2_2_6:
            n3 = 55;
            break;
        case NarrowWideV2_3_9:
            n3 = 56;
            break;
        case NarrowWideV2_4_12:
            n3 = 57;
            break;
    }
    
    unsigned char n4 = height;
    unsigned char *command = (unsigned char*)malloc(6 + barcodeDataSize + 1);
    command[0] = 0x1b;
    command[1] = 0x62;
    command[2] = n1;
    command[3] = n2;
    command[4] = n3;
    command[5] = n4;
    for (int index = 0; index < barcodeDataSize; index++)
    {
        command[index + 6] = barcodeData[index];
    }
    command[barcodeDataSize + 6] = 0x1e;
    int commandSize = 6 + barcodeDataSize + 1;
    
    NSData *dataToSentToPrinter = [[NSData alloc] initWithBytes:command length:commandSize];
    
    [self sendCommand:dataToSentToPrinter portName:portName portSettings:portSettings timeoutMillis:10000];
    
    [dataToSentToPrinter release];
    free(command);
}

/**
 * This function is used to print bar codes in the 128 format
 * portName - Port name to use for communication. This should be (TCP:<IPAddress>)
 * portSettings - Should be blank
 * barcodeData - These are the characters that will be printed in the bar code. The characters available for this bar code are listed in section 3-43 (Rev. 1.12). 
 * barcodeDataSize - This is the number of characters in the barcode.  This should be the size of the preceding parameter
 * option - This tell the printer weather put characters under the printed bar code or not.  This may also be used to line feed after the bar code is printed.
 * height - The height of the bar code.  This is measured in pixels
 * width - This is the number of dots per module.  This value should be between 1 to 3.  See section 3-42 (Rev. 1.12) for more information on the values.
 */
+ (void)PrintCode128WithPortname:(NSString*)portName portSettings:(NSString*)portSettings barcodeData:(unsigned char *)barcodeData barcodeDataSize:(unsigned int)barcodeDataSize barcodeOptions:(BarCodeOptions)option height:(unsigned char)height min_module_dots:(Min_Mod_Size)width
{
    unsigned char n1 = 0x36;
    unsigned char n2 = 0;
    switch (option)
    {
        case No_Added_Characters_With_Line_Feed:
            n2 = 49;
            break;
        case Adds_Characters_With_Line_Feed:
            n2 = 50;
            break;
        case No_Added_Characters_Without_Line_Feed:
            n2 = 51;
            break;
        case Adds_Characters_Without_Line_Feed:
            n2 = 52;
            break;
    }
    unsigned char n3 = 0;
    switch (width)
    {
        case _2_dots:
            n3 = 49;
            break;
        case _3_dots:
            n3 = 50;
            break;
        case _4_dots:
            n3 = 51;
            break;
    }
    unsigned char n4 = height;
    unsigned char *command = (unsigned char*)malloc(6 + barcodeDataSize + 1);
    command[0] = 0x1b;
    command[1] = 0x62;
    command[2] = n1;
    command[3] = n2;
    command[4] = n3;
    command[5] = n4;
    for (int index = 0; index < barcodeDataSize; index++)
    {
        command[index + 6] = barcodeData[index];
    }
    command[barcodeDataSize + 6] = 0x1e;
    int commandSize = 6 + barcodeDataSize + 1;
    
    NSData *dataToSentToPrinter = [[NSData alloc] initWithBytes:command length:commandSize];
    
    [self sendCommand:dataToSentToPrinter portName:portName portSettings:portSettings timeoutMillis:10000];
    
    [dataToSentToPrinter release];
    free(command);
}

#pragma mark 2D Barcode

/**
 * This function is used to print a qrcode on standard star printers
 * portName - Port name to use for communication. This should be (TCP:<IPAddress>)
 * portSettings - Should be blank
 * correctionLevel - The correction level for the qrcode.  The correction level can be 7, 15, 25, or 30.  See section 3-129 (Rev. 1.12).
 * model - The model to use when printing the qrcode. See section 3-129 (Rev. 1.12). 
 * cellSize - The cell size of the qrcode.  This value of this should be between 1 and 8. It is recommended that this value be 2 or less.
 * barCodeData - This is the characters in the qrcode.
 * barcodeDataSize - This is the number of characters that will be written into the qrcode.  This is the size of the preceding parameter
 */
+ (void)PrintQrcodeWithPortname:(NSString*)portName portSettings:(NSString*)portSettings correctionLevel:(CorrectionLevelOption)correctionLevel model:(Model)model cellSize:(unsigned char)cellSize barcodeData:(unsigned char*)barCodeData barcodeDataSize:(unsigned int)barCodeDataSize
{
    NSMutableData *commands = [[NSMutableData alloc] init];
    
    unsigned char modelCommand[] = {0x1b, 0x1d, 0x79, 0x53, 0x30, 0x00};
    switch(model)
    {
        case Model1:
            modelCommand[5] = 1;
            break;
        case Model2:
            modelCommand[5] = 2;
            break;
    }
    
    [commands appendBytes:modelCommand length:6];
    
    unsigned char correctionLevelCommand[] = {0x1b, 0x1d, 0x79, 0x53, 0x31, 0x00};
    switch (correctionLevel)
    {
        case Low:
            correctionLevelCommand[5] = 0;
            break;
        case Middle:
            correctionLevelCommand[5] = 1;
            break;
        case Q:
            correctionLevelCommand[5] = 2;
            break;
        case High:
            correctionLevelCommand[5] = 3;
            break;
    }
    [commands appendBytes:correctionLevelCommand length:6];
    
    unsigned char cellCodeSize[] = {0x1b, 0x1d, 0x79, 0x53, 0x32, 0x00};
    cellCodeSize[5] = cellSize;
    [commands appendBytes:cellCodeSize length:6];
    
    unsigned char qrcodeStart[] = {0x1b, 0x1d, 0x79, 0x44, 0x31, 0x00};
    [commands appendBytes:qrcodeStart length:6];
    unsigned char qrcodeLow = barCodeDataSize % 256;
    unsigned char qrcodeHigh = barCodeDataSize / 256;
    [commands appendBytes:&qrcodeLow length:1];
    [commands appendBytes:&qrcodeHigh length:1];
    [commands appendBytes:barCodeData length:barCodeDataSize];
    
    unsigned char printQrcodeCommand[] = {0x1b, 0x1d, 0x79, 0x50};
    [commands appendBytes:printQrcodeCommand length:4];
    
    [self sendCommand:commands portName:portName portSettings:portSettings timeoutMillis:10000];
    
    [commands release];
}

/**
 * This function is used to print a pdf417 bar code in a standard star printer
 * portName - Port name to use for communication. This should be (TCP:<IPAddress>)
 * portSettings - Should be blank
 * limit - Selection of the Method to use so specify the bar code size.  This is either 0 or 1. 0 is Use Limit method and 1 is Use Fixed method. See section 3-122 of the manual (Rev 1.12).
 * p1 - The vertical proportion to use.  The value changes with the limit select.  See section 3-122 of the manual (Rev 1.12).
 * p2 - The horizontal proportion to use.  The value changes with the limit select.  See section 3-122 of the manual (Rev 1.12).
 * securityLevel - This represents how well the bar code can be recovered if it is damaged. This value should be 0 to 8.
 * xDirection - Specifies the X direction size. This value should be from 1 to 10.  It is recommended that the value be 2 or less.
 * aspectRatio - Specifies the ratio of the pdf417.  This values should be from 1 to 10.  It is recommended that this value be 2 or less.
 * barcodeData - Specifies the characters in the pdf417 bar code.
 * barcodeDataSize - Specifies the amount of characters to put in the barcode.  This should be the size of the preceding parameter.
 */
+ (void)PrintPDF417CodeWithPortname:(NSString *)portName portSettings:(NSString *)portSettings limit:(Limit)limit p1:(unsigned char)p1 p2:(unsigned char)p2 securityLevel:(unsigned char)securityLevel xDirection:(unsigned char)xDirection aspectRatio:(unsigned char)aspectRatio barcodeData:(unsigned char[])barcodeData barcodeDataSize:(unsigned int)barcodeDataSize
{
    NSMutableData *commands = [[NSMutableData alloc] init];
    
    unsigned char setBarCodeSize[] = {0x1b, 0x1d, 0x78, 0x53, 0x30, 0x00, 0x00, 0x00};
    switch (limit)
    {
        case USE_LIMITS:
            setBarCodeSize[5] = 0;
            break;
        case USE_FIXED:
            setBarCodeSize[5] = 1;
            break;
    }
    setBarCodeSize[6] = p1;
    setBarCodeSize[7] = p2;
    
    [commands appendBytes:setBarCodeSize length:8];
    
    unsigned char setSecurityLevel[] = {0x1b, 0x1d, 0x78, 0x53, 0x31, 0x00};
    setSecurityLevel[5] = securityLevel;
    [commands appendBytes:setSecurityLevel length:6];
    
    unsigned char setXDirections[] = {0x1b, 0x1d, 0x78, 0x53, 0x32, 0x00};
    setXDirections[5] = xDirection;
    [commands appendBytes:setXDirections length:6];
    
    unsigned char setAspectRatio[] = {0x1b, 0x1d, 0x78, 0x53, 0x33, 0x00};
    setAspectRatio[5] = aspectRatio;
    [commands appendBytes:setAspectRatio length:6];
    
    unsigned char *setBarcodeData = (unsigned char*)malloc(6 + barcodeDataSize);
    setBarcodeData[0] = 0x1b;
    setBarcodeData[1] = 0x1d;
    setBarcodeData[2] = 0x78;
    setBarcodeData[3] = 0x44;
    setBarcodeData[4] = barcodeDataSize % 256;
    setBarcodeData[5] = barcodeDataSize / 256;
    for (int index = 0; index < barcodeDataSize; index++)
    {
        setBarcodeData[index + 6] = barcodeData[index];
    }
    [commands appendBytes:setBarcodeData length:6 + barcodeDataSize];
    free(setBarcodeData);
    
    unsigned char printBarcode[] = {0x1b, 0x1d, 0x78, 0x50};
    [commands appendBytes:printBarcode length:4];
    
    [self sendCommand:commands portName:portName portSettings:portSettings timeoutMillis:10000];
    
    [commands release];
}

#pragma mark Cut

/**
 * This function is intended to show how to get a legacy printer to cut the paper
 * portName - Port name to use for communication. This should be (TCP:<IPAddress>)
 * portSettings - Should be blank
 * cuttype - The cut type to perform, the cut types are full cut, full cut with feed, partial cut, and partial cut with feed
 */
+ (void)PerformCutWithPortname:(NSString *)portName portSettings:(NSString*)portSettings cutType:(CutType)cuttype
{
    unsigned char autocutCommand[] = {0x1b, 0x64, 0x00};
    switch (cuttype)
    {
        case FULL_CUT:
            autocutCommand[2] = 48;
            break;
        case PARCIAL_CUT:
            autocutCommand[2] = 49;
            break;
        case FULL_CUT_FEED:
            autocutCommand[2] = 50;
            break;
        case PARTIAL_CUT_FEED:
            autocutCommand[2] = 51;
            break;
    }
    
    int commandSize = 3;
    
    NSData *dataToSentToPrinter = [[NSData alloc] initWithBytes:autocutCommand length:commandSize];
    
    [self sendCommand:dataToSentToPrinter portName:portName portSettings:portSettings timeoutMillis:10000];
    
    [dataToSentToPrinter release];
}

#pragma mark Text Formatting

/**
 * This function prints raw text to the print.  It show how the text can be formated.  For example changing its size.
 * portName - Port name to use for communication. This should be (TCP:<IPAddress>)
 * portSettings - Should be blank
 * slashedZero - boolean variable to tell the printer to weather to put a slash in the zero characters that it print
 * underline - boolean variable that Tells the printer if should underline the text
 * invertColor - boolean variable that tells the printer if it should invert the text its printing.  All White space will become black and the characters will be left white
 * emphasized - boolean variable that tells the printer if it should emphasize the printed text.  This is sort of like bold but not as dark, but darker then regular characters.
 * upperline - boolean variable that tells the printer if to place a line above the text.  This only supported by new printers.
 * upsideDown - boolean variable that tells the printer if the text should be printed upside-down
 * heightExpansion - This integer tells the printer what multiple the character height should be, this should be from 0 to 5 representing multiples from 1 to 6
 * widthExpansion - This integer tell the printer what multiple the character width should be, this should be from 0 to 5 representing multiples from 1 to 6.
 * leftMargin - The left margin for the text.  Although the max value for this can be 255, the value shouldn't get that high or the text could be pushed off the page.
 * alignment - The alignment of the text. The printers support left, right, and center justification
 * textData - The text to print
 * textDataSize - The amount of text to send to the printer
 */
+ (void)PrintTextWithPortname:(NSString *)portName portSettings:(NSString*)portSettings slashedZero:(bool)slashedZero underline:(bool)underline invertColor:(bool)invertColor emphasized:(bool)emphasized upperline:(bool)upperline upsideDown:(bool)upsideDown heightExpansion:(int)heightExpansion widthExpansion:(int)widthExpansion leftMargin:(unsigned char)leftMargin alignment: (Alignment)alignment textData:(unsigned char*)textData textDataSize:(unsigned int)textDataSize
{
    NSMutableData *commands = [[NSMutableData alloc] init];
    
	unsigned char initial[] = {0x1b, 0x40};
	[commands appendBytes:initial length:2];
	
    unsigned char slashedZeroCommand[] = {0x1b, 0x2f, 0x00};
    if (slashedZero)
    {
        slashedZeroCommand[2] = 49;
    }
    else
    {
        slashedZeroCommand[2] = 48;
    }
    [commands appendBytes:slashedZeroCommand length:3];
    
    unsigned char underlineCommand[] = {0x1b, 0x2d, 0x00};
    if (underline)
    {
        underlineCommand[2] = 49;
    }
    else
    {
        underlineCommand[2] = 48;
    }
    [commands appendBytes:underlineCommand length:3];
    
    unsigned char invertColorCommand[] = {0x1b, 0x00};
    if (invertColor)
    {
        invertColorCommand[1] = 0x34;
    }
    else
    {
        invertColorCommand[1] = 0x35;
    }
    [commands appendBytes:invertColorCommand length:2];
    
    unsigned char emphasizedPrinting[] = {0x1b, 0x00};
    if (emphasized)
    {
        emphasizedPrinting[1] = 69;
    }
    else
    {
        emphasizedPrinting[1] = 70;
    }
    [commands appendBytes:emphasizedPrinting length:2];
    
    unsigned char upperLineCommand[] = {0x1b, 0x5f, 0x00};
    if (upperline)
    {
        upperLineCommand[2] = 0x49;
    }
    else
    {
        upperLineCommand[2] = 0x48;
    }
    [commands appendBytes:upperLineCommand length:3];
    
    if (upsideDown)
    {
        unsigned char upsd = 0x0f;
        [commands appendBytes:&upsd length:1];
    }
    else
    {
        unsigned char upsd = 0x12;
        [commands appendBytes:&upsd length:1];
    }
    
    unsigned char characterExpansion[] = {0x1b, 0x69, 0x00, 0x00};
    characterExpansion[2] = heightExpansion + '0';
    characterExpansion[3] = widthExpansion + '0';
    [commands appendBytes:characterExpansion length:4];
    
    unsigned char leftMarginCommand[] = {0x1b, 0x6c, 0x00};
    leftMarginCommand[2] = leftMargin;
    [commands appendBytes:leftMarginCommand length:3];
    
    unsigned char alignmentCommand[] = {0x1b, 0x1d, 0x61, 0x00};
    switch (alignment)
    {
        case Left:
            alignmentCommand[3] = 48;
            break;
        case Center:
            alignmentCommand[3] = 49;
            break;
        case Right:
            alignmentCommand[3] = 50;
            break;
    }
    [commands appendBytes:alignmentCommand length:4];
    
    [commands appendBytes:textData length:textDataSize];
    
    unsigned char lf = 0x0a;
    [commands appendBytes:&lf length:1];
    
    [self sendCommand:commands portName:portName portSettings:portSettings timeoutMillis:10000];
    
    [commands release];
}

/**
 * This function prints raw Kanji text to the print.  It show how the text can be formated.  For example changing its size.
 * portName - Port name to use for communication. This should be (TCP:<IPAddress>)
 * portSettings - Should be blank
 * kanjiMode - The segment index of Japanese Kanji mode that Tells the printer to weather Shift-JIS or JIS.
 * underline - boolean variable that Tells the printer if should underline the text
 * invertColor - boolean variable that tells the printer if it should invert the text its printing.  All White space will become black and the characters will be left white
 * emphasized - boolean variable that tells the printer if it should emphasize the printed text.  This is sort of like bold but not as dark, but darker then regular characters.
 * upperline - boolean variable that tells the printer if to place a line above the text.  This only supported by new printers.
 * upsideDown - boolean variable that tells the printer if the text should be printed upside-down
 * heightExpansion - This integer tells the printer what multiple the character height should be, this should be from 0 to 5 representing multiples from 1 to 6
 * widthExpansion - This integer tell the printer what multiple the character width should be, this should be from 0 to 5 representing multiples from 1 to 6.
 * leftMargin - The left margin for the text.  Although the max value for this can be 255, the value shouldn't get that high or the text could be pushed off the page.
 * alignment - The alignment of the text. The printers support left, right, and center justification
 * textData - The text to print
 * textDataSize - The amount of text to send to the printer
 */
+ (void)PrintKanjiTextWithPortname:(NSString *)portName portSettings:(NSString*)portSettings kanjiMode:(int)kanjiMode underline:(bool)underline invertColor:(bool)invertColor emphasized:(bool)emphasized upperline:(bool)upperline upsideDown:(bool)upsideDown heightExpansion:(int)heightExpansion widthExpansion:(int)widthExpansion leftMargin:(unsigned char)leftMargin alignment:(Alignment)alignment textData:(unsigned char*)textData textDataSize:(unsigned int)textDataSize
{
    NSMutableData *commands = [[NSMutableData alloc] init];

	unsigned char initial[] = {0x1b, 0x40};
	[commands appendBytes:initial length:2];
		
    unsigned char kanjiModeCommand[] = {0x1b, 0x24, 0x00, 0x1b, 0x00};
    if (kanjiMode == 0)	// Shift-JIS
    {
        kanjiModeCommand[2] = 0x01;
        kanjiModeCommand[4] = 0x71;
    }
    else				// JIS
    {
        kanjiModeCommand[2] = 0x00;
        kanjiModeCommand[4] = 0x70;
    }
    [commands appendBytes:kanjiModeCommand length:5];
    
    unsigned char underlineCommand[] = {0x1b, 0x2d, 0x00};
    if (underline)
    {
        underlineCommand[2] = 49;
    }
    else
    {
        underlineCommand[2] = 48;
    }
    [commands appendBytes:underlineCommand length:3];
    
    unsigned char invertColorCommand[] = {0x1b, 0x00};
    if (invertColor)
    {
        invertColorCommand[1] = 0x34;
    }
    else
    {
        invertColorCommand[1] = 0x35;
    }
    [commands appendBytes:invertColorCommand length:2];
    
    unsigned char emphasizedPrinting[] = {0x1b, 0x00};
    if (emphasized)
    {
        emphasizedPrinting[1] = 69;
    }
    else
    {
        emphasizedPrinting[1] = 70;
    }
    [commands appendBytes:emphasizedPrinting length:2];
    
    unsigned char upperLineCommand[] = {0x1b, 0x5f, 0x00};
    if (upperline)
    {
        upperLineCommand[2] = 0x49;
    }
    else
    {
        upperLineCommand[2] = 0x48;
    }
    [commands appendBytes:upperLineCommand length:3];
    
    if (upsideDown)
    {
        unsigned char upsd = 0x0f;
        [commands appendBytes:&upsd length:1];
    }
    else
    {
        unsigned char upsd = 0x12;
        [commands appendBytes:&upsd length:1];
    }
    
    unsigned char characterExpansion[] = {0x1b, 0x69, 0x00, 0x00};
    characterExpansion[2] = heightExpansion + '0';
    characterExpansion[3] = widthExpansion + '0';
    [commands appendBytes:characterExpansion length:4];
    
    unsigned char leftMarginCommand[] = {0x1b, 0x6c, 0x00};
    leftMarginCommand[2] = leftMargin;
    [commands appendBytes:leftMarginCommand length:3];
    
    unsigned char alignmentCommand[] = {0x1b, 0x1d, 0x61, 0x00};
    switch (alignment)
    {
        case Left:
            alignmentCommand[3] = 48;
            break;
        case Center:
            alignmentCommand[3] = 49;
            break;
        case Right:
            alignmentCommand[3] = 50;
            break;
    }
    [commands appendBytes:alignmentCommand length:4];
    
    [commands appendBytes:textData length:textDataSize];
    
    unsigned char lf = 0x0a;
    [commands appendBytes:&lf length:1];
    
    [self sendCommand:commands portName:portName portSettings:portSettings timeoutMillis:10000];

    [commands release];
}

#pragma mark common

/**
 * This function is used to print a uiimage directly to the printer.
 * There are 2 ways a printer can usually print images, one is through raster commands the other is through line mode commands
 * This function uses raster commands to print an image.  Raster is support on the tsp100 and all legacy thermal printers
 * The line mode printing is not supported by the tsp100 so its not used
 * portName - Port name to use for communication. This should be (TCP:<IPAddress>)
 * portSettings - Should be blank
 * source - the uiimage to convert to star raster data
 * maxWidth - the maximum with the image to print.  This is usually the page with of the printer.  If the image exceeds the maximum width then the image is scaled down.  The ratio is maintained. 
 */
+ (void)PrintImageWithPortname:(NSString *)portName portSettings:(NSString*)portSettings imageToPrint:(UIImage*)imageToPrint maxWidth:(int)maxWidth compressionEnable:(BOOL)compressionEnable withDrawerKick:(BOOL)drawerKick
{
    RasterDocument *rasterDoc = [[RasterDocument alloc] initWithDefaults:RasSpeed_Medium endOfPageBehaviour:RasPageEndMode_FeedAndFullCut endOfDocumentBahaviour:RasPageEndMode_FeedAndFullCut topMargin:RasTopMargin_Standard pageLength:0 leftMargin:0 rightMargin:0];
    StarBitmap *starbitmap = [[StarBitmap alloc] initWithUIImage:imageToPrint :maxWidth :false];
    
    NSMutableData *commandsToPrint = [[NSMutableData alloc] init];
    NSData *shortcommand = [rasterDoc BeginDocumentCommandData];
    [commandsToPrint appendData:shortcommand];
    
    shortcommand = [starbitmap getImageDataForPrinting:compressionEnable];
    [commandsToPrint appendData:shortcommand];
    
    shortcommand = [rasterDoc EndDocumentCommandData];
    [commandsToPrint appendData:shortcommand];
    
    if (drawerKick == YES) {
        [commandsToPrint appendBytes:"\x07"
                              length:sizeof("\x07") - 1];    // KickCashDrawer
    }
    
    [starbitmap release];
    [rasterDoc release];
    
    [self sendCommand:commandsToPrint portName:portName portSettings:portSettings timeoutMillis:10000];

    [commandsToPrint release];
}

+ (void)sendCommand:(NSData *)commandsToPrint portName:(NSString *)portName portSettings:(NSString *)portSettings timeoutMillis:(u_int32_t)timeoutMillis
{
    int commandSize = [commandsToPrint length];
    unsigned char *dataToSentToPrinter = (unsigned char *)malloc(commandSize);
    [commandsToPrint getBytes:dataToSentToPrinter];
    
    SMPort *starPort = nil;
    @try
    {
        starPort = [SMPort getPort:portName :portSettings :timeoutMillis];
        if (starPort == nil)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fail to Open Port"
                                                            message:@""
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
            return;
        }
        
        StarPrinterStatus_2 status;
        [starPort beginCheckedBlock:&status :2];
        if (status.offline == SM_TRUE) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Printer is offline"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
            return;
        }
        
        struct timeval endTime;
        gettimeofday(&endTime, NULL);
        endTime.tv_sec += 30;
        
        int totalAmountWritten = 0;
        while (totalAmountWritten < commandSize)
        {
            int remaining = commandSize - totalAmountWritten;
            int amountWritten = [starPort writePort:dataToSentToPrinter :totalAmountWritten :remaining];
            totalAmountWritten += amountWritten;
            
            struct timeval now;
            gettimeofday(&now, NULL);
            if (now.tv_sec > endTime.tv_sec)
            {
                break;
            }
        }
        
        if (totalAmountWritten < commandSize)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Printer Error"
                                                            message:@"Write port timed out"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
        
        [starPort endCheckedBlock:&status :2];
        if (status.offline == SM_TRUE) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Printer is offline"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
            return;
        }
    }
    @catch (PortException *exception)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Printer Error"
                                                        message:@"Write port timed out"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    @finally
    {
        free(dataToSentToPrinter);
        [SMPort releasePort:starPort];
    }
}

#pragma mark diconnect bluetooth

+ (void)disconnectPort:(NSString *)portName portSettings:(NSString *)portSettings timeout:(u_int32_t)timeout {
    SMPort *port = [SMPort getPort:portName :portSettings :timeout];
    if (port == nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fail to Open Port"
                                                        message:@""
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    
    BOOL result = [port disconnect];
    if (result == NO) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fail to Disconnect" message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
        [alert release];
        return;
    }
    
    [SMPort releasePort:port];
}

@end