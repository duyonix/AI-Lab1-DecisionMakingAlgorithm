struct POMG
    Ī³  # discount factor
    ā  # agents
    š®  # state space
    š  # joint action space
    šŖ  # joint observation space
    T  # transition function
    O  # joint observation function
    R  # joint reward function
end

function POMG(pomg::BabyPOMG)
    return POMG(
        pomg.babyPOMDP.Ī³, # discount factor
        vec(collect(1:n_agents(pomg))), # agents
        ordered_states(pomg), # state
        [ordered_actions(pomg, i) for i in 1:n_agents(pomg)], # joint action space
        [ordered_observations(pomg, i) for i in 1:n_agents(pomg)], # joint observation space
        (s, a, sā²) -> transition(pomg, s, a, sā²),  # Transition(s'|s, a)
        (a, sā², o) -> joint_observation(pomg, a, sā², o), # joint observation function
        (s, a) -> joint_reward(pomg, s, a) # Reward(s, a)
    )
end

function lookahead(š«::POMG, U, s, a)
    š®, šŖ, T, O, R, Ī³ = š«.š®, joint(š«.šŖ), š«.T, š«.O, š«.R, š«.Ī³
    uā² = sum(T(s, a, sā²) * sum(O(a, sā², o) * U(o, sā²) for o in šŖ) for sā² in š®)
    return R(s, a) + Ī³ * uā²
end

function evaluate_plan(š«::POMG, Ļ, s)
    # compute utility of conditional plan 
    a = Tuple(Ļi() for Ļi in Ļ)
    U(o, sā²) = evaluate_plan(š«, [Ļi(oi) for (Ļi, oi) in zip(Ļ, o)], sā²)
    return isempty(first(Ļ).subplans) ? š«.R(s, a) : lookahead(š«, U, s, a) # equation (26.1) page 528
end

function utility(š«::POMG, b, Ļ)
    # compute utility of policy Ļ from initial state distibution b
    u = [evaluate_plan(š«, Ļ, s) for s in š«.š®]
    return sum(bs * us for (bs, us) in zip(b, u)) # equation (26.2) page 528
end