module Util

  class Services < Array

    def initialize(raw)
            concat raw.values.flatten
          end

          # Compares the name, label, and tags of each service to the given +filter+.  The method returns the first service
          # that the +filter+ matches.  If no service matches, returns +nil+.
          #
          # @param [Regexp, String] filter a +RegExp+ or +String+ to match against the name, label, and tags of the services
          # @param [String] required_credentials an optional list of keys or groups of keys, where at least one key from the
          #                                      group, must exist in the credentials payload of the candidate service
          # @return [Hash, nil] the first service that +filter+ matches.  If no service matches, returns +nil+.
          def find_service(filter, *required_credentials)
            select(&service?(filter))
              .find(&credentials?(required_credentials))
          end

          # Compares the name, label, and tags of each service to the given +filter+. The method returns the first service
          # that +filter+ matches.  If no service matches, returns +nil+.
          #
          # @param [Regexp, String] filter a +RegExp+ or +String+ to match against the name, label, and tags of the services
          # @return [Hash, nil] the first service that +filter+ matches.  If no service matches, returns +nil+.
          def find_volume_service(filter)
            select(&service?(filter))
              .find(&volume_mount?)
          end

          # Compares the name, label, and tags of each service to the given +filter+.  The method returns +true+ if the
          # +filter+ matches exactly one service, +false+ otherwise.
          #
          # @param [Regexp, String] filter a +RegExp+ or +String+ to match against the name, label, and tags of the services
          # @param [String] required_credentials an optional list of keys or groups of keys, where at least one key from the
          #                                      group, must exist in the credentials payload of the candidate service
          # @return [Boolean] +true+ if the +filter+ matches exactly one service with the required credentials, +false+
          #                   otherwise.
          def one_service?(filter, *required_credentials)
            select(&service?(filter))
              .select(&credentials?(required_credentials))
              .one?
          end

          # Compares the name, label, and tags of each service to the given +filter+. The method returns +true+ if the
          # +filter+ matches exactly one volume service, +false+ otherwise.
          #
          # @param [Regexp, String] filter a +RegExp+ or +String+ to match against the name, label, and tags of the services
          # @return [Boolean] +true+ if the +filter+ matches exactly one volume service with the required credentials,
          #                   +false+ otherwise.
          def one_volume_service?(filter)
            select(&service?(filter))
              .select(&volume_mount?)
              .one?
          end

          private

          def credentials?(required_keys)
            lambda do |service|
              credentials = service['credentials']
              return false if credentials.nil?

              required_keys.all? do |k|
                k.is_a?(Array) ? k.any? { |g| credentials.key?(g) } : credentials.key?(k)
              end
            end
          end

          def volume_mount?
            lambda do |service|
              volume_mounts = service['volume_mounts']
              return false if volume_mounts.nil?

              volume_mounts.one?
            end
          end

          def service?(filter)
            filter = Regexp.new(filter) unless filter.is_a?(Regexp)

            lambda do |service|
              service['name'] =~ filter || service['label'] =~ filter || service['tags'].any? { |tag| tag =~ filter }
            end
          end

  end

end
