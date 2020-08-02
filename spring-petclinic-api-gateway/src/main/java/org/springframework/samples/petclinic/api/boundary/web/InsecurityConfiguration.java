package org.springframework.samples.petclinic.api.boundary.web;


import org.springframework.context.annotation.Bean;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;

@EnableWebFluxSecurity
public class InsecurityConfiguration {
    //@formatter:off
    @Bean
    public SecurityWebFilterChain springSecurityFilterChain(ServerHttpSecurity http) {
    	return http
                .authorizeExchange().anyExchange().permitAll()
                .and()
                .csrf().disable()
                .build();
    }
}
