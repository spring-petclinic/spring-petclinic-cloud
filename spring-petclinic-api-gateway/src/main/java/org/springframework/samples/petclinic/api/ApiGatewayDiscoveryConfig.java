package org.springframework.samples.petclinic.api;

import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

//@Profile("!cloud")
@Configuration
@EnableDiscoveryClient
public class ApiGatewayDiscoveryConfig {

}
