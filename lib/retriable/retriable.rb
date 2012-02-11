# encoding: utf-8

require 'timeout'

module Retriable
  class Retry
    attr_accessor :tries
    attr_accessor :interval
    attr_accessor :timeout
    attr_accessor :on
    attr_accessor :on_retry

    def initialize
      @tries      = 3
      @interval   = 0
      @timeout    = nil
      @on         = Exception
      @on_retry   = nil

      yield self if block_given?
    end

    def perform
      count = 0
      begin
        if @timeout
          Timeout::timeout(@timeout) { yield }
        else
          yield
        end
      rescue *[*on] => exception
        @tries -= 1
        if @tries > 0
          count += 1
          sleep @interval if @interval > 0
          @on_retry.call(exception, count) if @on_retry
          retry
        else
          raise
        end
      end
    end
  end

  def retriable(options = {}, &block)
    opts = {
      :tries => 3,
      :on => Exception,
      :interval => 1
    }

    opts.merge!(options)

    raise 'No block given' unless block_given?

    Retry.new do |r|
      r.tries      = opts[:tries]
      r.on         = opts[:on]
      r.interval   = opts[:interval]
      r.timeout    = opts[:timeout] if opts[:timeout]
      r.on_retry   = opts[:on_retry] if opts[:on_retry]
    end.perform(&block)
  end
end
