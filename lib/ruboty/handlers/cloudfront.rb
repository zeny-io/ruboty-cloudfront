require 'securerandom'
require 'uri'
require 'aws-sdk'

module Ruboty
  module Handlers
    class Cloudfront < Base
      on(
        /cf list distributions?/m,
        description: 'List distributions',
        name: 'list_distributuions'
      )

      on(
        /cf list invalidations?/m,
        description: 'List invalidations',
        name: 'list_invalidations'
      )

      on(
        /cf (?:inval(?:idate)?|purge) (?<url>.+?)\z/m,
        description: 'Purge path',
        name: 'purge_url'
      )

      def list_distributuions(message)
        maximum_domain_length = prefixes.map(&:first).sort_by(&:size).last.size
        maximum_id_length = prefixes.map { |p| p[1] }.sort_by(&:size).last.size

        lines = prefixes.map do |prefix|
          [
            prefix[0].ljust(maximum_domain_length),
            prefix[1].ljust(maximum_id_length),
            prefix[2]
          ].join(' ')
        end

        message.reply(
          "We have #{prefixes.count} distributions\n" + lines.join("\n"),
          code: true
        )
      end

      def list_invalidations(message)
        invalidations = []
        prefixes.map { |p| p[1] }.uniq.each do |prefix|
          resp = cloudfront.list_invalidations(distribution_id: prefix)
          resp.invalidation_list.items.each do |invalidation|
            next unless invalidation.status != 'Completed'
            iresp = cloudfront.get_invalidation(distribution_id: prefix, id: invalidation.id)
            iresp.invalidation.invalidation_batch.paths.items.each do |path|
              invalidations << "#{path} : #{invalidation.status} / #{domains_by(prefix).join(', ')}"
            end
          end
        end

        message.reply(
          "We have #{invalidations.count} invalidations\n" + invalidations.join("\n"),
          code: true
        )
      end

      def purge_url(message)
        uri = URI.parse(message[:url])

        dist = prefixes.bsearch { |p| p[0] == uri.host }

        unless dist
          message.reply('Distribution not found')
          return
        end

        cloudfront.create_invalidation(distribution_id: dist[1],
                                       invalidation_batch: {
                                         paths: {
                                           quantity: 1,
                                           items: [uri.path]
                                         },
                                         caller_reference: SecureRandom.uuid
                                       })

        message.reply("Started #{uri.path} invalidation of #{dist[1]} / #{dist[0]}")
      end

      private

      def cloudfront
        @cloudfront ||= Aws::CloudFront::Client.new(region: 'us-east-1')
      end

      def distributions
        cloudfront.list_distributions.distribution_list
      rescue Aws::Errors::ServiceError
        nil
      end

      def prefixes
        return @prefixes if @prefixes

        @prefixes = []
        distributions.items.each do |dist|
          @prefixes << [dist.domain_name, dist.id, dist.status]
          dist.aliases.items.each do |domain|
            @prefixes << [domain, dist.id, dist.status]
          end
        end
        @prefixes
      end

      def domains_by(id)
        prefixes.select { |p| p[1] == id }.map(&:first)
      end
    end
  end
end
