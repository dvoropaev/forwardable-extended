# Frozen-string-literal: true
# Copyright: 2015-2016 Jordon Bedwell - MIT License
# Encoding: utf-8

require "forwardable/extended/version"
require "forwardable"

module Forwardable
  module Extended
    DEF_DELEGATOR = Object::Forwardable.instance_method(:def_delegator)
    def def_hash_delegator(hash, method, key: method, bool: false, wrap: false)
      prefix = (bool == :reverse ? "!!!" : "!!") if bool
      wrap = "self.class.new" if wrap.is_a?(TrueClass)
      wrap = wrap ? "#{wrap} " : ""
      suffix = (bool ? "?" : "")

      class_eval <<-STR, __FILE__, __LINE__
        def #{method}#{suffix}
          #{wrap}#{prefix}#{hash}[#{key.inspect}]
        end
      STR
    end

    #

    def def_ivar_delegator(ivar, alias_ = ivar, bool: false, wrap: false)
      prefix = (bool == :reverse ? "!!!" : "!!") if bool
      wrap = "self.class.new" if wrap.is_a?(TrueClass)
      wrap = wrap ? "#{wrap} " : ""
      suffix = (bool ? "?" : "")

      class_eval <<-STR, __FILE__, __LINE__
        def #{alias_.to_s.gsub(/\A@/, "")}#{suffix}
          #{wrap}#{prefix}#{ivar}
        end
      STR
    end

    #

    def def_delegator(accessor, method, alias_ = method, **kwd)
      kwd, alias_ = alias_, method if alias_.is_a?(Hash) && !kwd.any?

      if alias_.is_a?(Hash) || !kwd.any?
        DEF_DELEGATOR.bind(self).call(
          accessor, method, alias_
        )

      elsif kwd[:type]
        raise ArgumentError, "Alias not supported with type; the method is the alias" if alias_ != method
        send("def_#{kwd[:type]}_delegator", accessor, method, **kwd.tap { |obj|
          obj.delete(:type)
        })

      else
        def_modern_delegator(
          accessor, method, alias_, **kwd
        )
      end
    end

    #

    def def_modern_delegator(accessor, method, alias_ = method, args: [], bool: false, wrap: false)
      args = [args].flatten.compact.map(&:to_s).unshift("").join(", ")
      prefix = (bool == :reverse ? "!!!" : "!!") if bool
      wrap = "self.class.new" if wrap.is_a?(TrueClass)
      wrap = wrap ? "#{wrap} " : ""
      suffix = (bool ? "?" : "")

      class_eval <<-STR, __FILE__, __LINE__
        def #{alias_}#{suffix}(*args, &block)
          #{wrap}#{prefix}#{accessor}.send(#{method.inspect}#{args + ", *args"}, &block)
        end
      STR
    end
  end
end
