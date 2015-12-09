# Copyright 2011-2012 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

require 'aws/record/validator'

module AWS
  module Record
    
    # Uses the base validator class to call user-defined validation methods.
    # @private
    class MethodValidator < Validator

      ACCEPTED_OPTIONS = [:on, :if, :unless]

      def validate_attributes record
        attribute_names.each do |method_name|
          record.send(method_name)
        end
      end

    end
  end
end
