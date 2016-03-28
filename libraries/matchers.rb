if defined?(ChefSpec)
    def init_couchbase_cluster(resource)
        ChefSpec::Matchers::ResourceMatcher.new(:couchbase_cluster,
                                                :init,
                                                resource)
    end

    def modify_couchbase_cluster(resource)
        ChefSpec::Matchers::ResourceMatcher.new(:couchbase_cluster,
                                                :modify,
                                                resource)
    end

    def join_couchbase_cluster(resource)
        ChefSpec::Matchers::ResourceMatcher.new(:couchbase_cluster,
                                                :join,
                                                resource)
    end

    def modify_couchbase_node(resource)
        ChefSpec::Matchers::ResourceMatcher.new(:couchbase_node,
                                                :modify,
                                                resource)
    end
end
