package com.hotel.sistema.config;

import org.springframework.context.annotation.*;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .authorizeHttpRequests(auth -> auth
                        // Publico
                        .requestMatchers("/css/**", "/js/**", "/images/**").permitAll()
                        .requestMatchers("/login", "/registro").permitAll()

                        // Solo ADMIN
                        .requestMatchers("/usuarios/**").hasRole("ADMIN")
                        .requestMatchers("/habitaciones/nueva", "/habitaciones/editar/**", "/habitaciones/eliminar/**")
                        .hasRole("ADMIN")
                        .requestMatchers("/productos/nuevo", "/productos/guardar", "/productos/editar/**",
                                "/productos/eliminar/**")
                        .hasRole("ADMIN")

                        // ADMIN y RECEPCIONISTA — gestion completa
                        .requestMatchers("/reservaciones/cancelar/**").hasAnyRole("ADMIN", "RECEPCIONISTA")

                        // ADMIN, RECEPCIONISTA y CLIENTE — con acceso diferenciado por vista
                        .requestMatchers("/reservaciones/**").hasAnyRole("ADMIN", "RECEPCIONISTA", "CLIENTE")
                        .requestMatchers("/pagos/**").hasAnyRole("ADMIN", "RECEPCIONISTA", "CLIENTE")
                        .requestMatchers("/habitaciones/**").hasAnyRole("ADMIN", "RECEPCIONISTA", "CLIENTE")
                        .requestMatchers("/productos/**").hasAnyRole("ADMIN", "RECEPCIONISTA", "CLIENTE")
                        .requestMatchers("/ofertas/**").hasAnyRole("ADMIN", "RECEPCIONISTA")
                        .requestMatchers("/cargos-extra/**").hasAnyRole("ADMIN", "RECEPCIONISTA")

                        // Dashboard
                        .requestMatchers("/dashboard", "/").hasAnyRole("ADMIN", "RECEPCIONISTA", "CLIENTE")

                        .anyRequest().authenticated())
                .formLogin(form -> form
                        .loginPage("/login")
                        .loginProcessingUrl("/login")
                        .defaultSuccessUrl("/dashboard", true)
                        .failureUrl("/login?error=true")
                        .permitAll())
                .logout(logout -> logout
                        .logoutUrl("/logout")
                        .logoutSuccessUrl("/login?logout=true")
                        .invalidateHttpSession(true)
                        .deleteCookies("JSESSIONID")
                        .permitAll());

        return http.build();
    }
}
