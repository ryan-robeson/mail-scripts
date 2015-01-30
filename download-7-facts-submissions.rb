#!/usr/bin/env ruby

# Copyright (c) 2015 Ryan Robeson
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Download 7 facts submissions from Goldmail.
# As students don't always use the correct subject,
# this script downloads anything from a Goldmail
# address with an attachment.
# Attachments are downloaded and then messages
# are archived.
# Use with care.

require "bundler"
Bundler.require

credential_path = Pathname.new "creds.yaml"
download_dir = Pathname.new "7facts"
FileUtils.mkdir_p download_dir unless download_dir.exist?

# Make the script idempotent by only touching
# new messages.
record_path = download_dir + "record.yaml"

if record_path.exist?
  record = YAML.load_file record_path
end

record ||= []

creds = YAML.load_file(credential_path)[:goldmail]

classes = %w[023 035 060] # Used to match the subject lines to the right classes.

class_paths = classes.map { |c| download_dir +  c }
(class_paths << download_dir + "unknown").each do |cp|
  FileUtils.mkdir cp unless cp.exist?
end

classes << ".+" # To match any leftovers at the end.

Luggage.new server: %w(imap.gmail.com 993 true), login: [creds[:username], creds[:password]] do
  mailboxes :inbox do
    # Use GMAIL search tools
    results = where("X-GM-RAW" => %q{has:attachment AND from:goldmail.etsu.edu})
    results.each do |m|
      unless record.include? m.message_id
        record << m.message_id
        subject = m.subject

        # Figure out which class the message belongs to
        classes.each_with_index do |c, i|
          if subject.match(/#{c}/)
            puts "Match found for #{subject} at #{i} with #{c}. Path: #{class_paths[i]}"
            m.attachments.each do |a|
              filename = class_paths[i] + "#{subject}-#{a.filename}"
              puts "Saving to #{filename}"
              begin
                File.open(filename, "w+b", 0644) {|f| f.write a.body.decoded}
                # Archive the message
                puts "Archiving message... Subject: #{subject} | From: #{m.from}"
                puts
                m.copy_to!(:g_all)
                m.delete!
              rescue => e
                puts "Unable to save data for #{filename}. Error: #{e.message}"
              end
            end

            # Move on to the next message
            break
          end
        end
      end
    end
  end.save!
end

File.open record_path, "w" do |r|
  r.write record.to_yaml
end

puts "All done."
exit 0
