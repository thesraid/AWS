#!/usr/bin/env python

"""
joriordan@alienvault.com
Script to send an email
"""
import smtplib
import os
from email import encoders
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText
from email.MIMEBase import MIMEBase
import argparse

sendr = "SENDER ADDRESS HERE"

"""
Get command line args from the user.
"""
def get_args():
    parser = argparse.ArgumentParser(
        description='Recipient, subject and email body')

    parser.add_argument('-r', '--recipient',
                        nargs='+',
                        required=True,
                        action='store',
                        help='Email addresses to send to')

    parser.add_argument('-s', '--subject',
                        required=True,
                        action='store',
                        help='EMail subject')

    parser.add_argument('-b', '--body',
                        required=True,
                        action='store',
                        help='EMail body')

    parser.add_argument('-a', '--attachment',
                        required=False,
                        action='store',
                        help='Path to attachment [Optional]')

    args = parser.parse_args()

    return args

""" 
Main module
"""
def main():

   args = get_args()

   recipients = args.recipient
   
   msg = MIMEMultipart()
   msg['From'] = sendr
   msg['To'] = ", ".join(recipients)
   msg['Subject'] = args.subject
   msg.attach(MIMEText(args.body, 'html'))


   if args.attachment:
      filename = os.path.basename(args.attachment)
      attachment = open(args.attachment, "rb")
 
      part = MIMEBase('application', 'octet-stream')
      part.set_payload((attachment).read())
      encoders.encode_base64(part)
      part.add_header('Content-Disposition', "attachment; filename= %s" % filename)
 
      msg.attach(part)

   server = smtplib.SMTP('SMTP SERVER HERE', 587)
   server.starttls()
   server.set_debuglevel(1)
   server.login("USERNAME", "PASSWORD")
   server.sendmail(sendr, args.recipient, msg.as_string())
   server.quit()

"""
Start program 
"""
if __name__ == "__main__":
    main()

