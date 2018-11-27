#!/usr/bin/env python

"""
joriordan@alienvault.com
Script to send an email
"""
import smtplib

sendr = "sender@domain.com"
recvr = "receiver@domain.com"
 
server = smtplib.SMTP('smtp.server.com', 587)
server.starttls()
server.set_debuglevel(1)
server.login("USER", "PASSWORD")
 
msg = "From: " + sendr + "\r\nTo: " + recvr + "\r\nSubject: Automated Email\r\n\r\nLine1\nLine2\nLine3"
server.sendmail(sendr, recvr, msg)
server.quit()
