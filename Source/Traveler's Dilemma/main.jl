# Our code is based on the book "Algorithm for Decision Making" by Mykel J. Kochenderfer, Tim A. Wheeler, Kyle Wray
# from The MIT Press; Cambridge, Massachusetts; London, England


using JuMP
using LinearAlgebra
using Plots
include("../helpers/SimpleGame/SimpleGame.jl")

struct Travelers end    # Model for Game Theory: Travelers Dilemma 

n_agents(simpleGame::Travelers) = 2 # represented for number of agents in the game

ordered_actions(simpleGame::Travelers, i::Int) = 2:100  # each traveler has to choose 1 integer from 2 to 100

# Vector of ordered actions for n_agents(simpleGame::Travelers)
ordered_joint_actions(simpleGame::Travelers) = vec(
    collect(Iterators.product([ordered_actions(simpleGame, i) for i = 1:n_agents(simpleGame)]...))
)

n_joint_actions(simpleGame::Travelers) = length(ordered_joint_actions(simpleGame))  # number of joint actions
n_actions(simpleGame::Travelers, i::Int) = length(ordered_actions(simpleGame, i))   # number of actions for each agent

# function to produce reward for traveler i in the game
function reward(simpleGame::Travelers, i::Int, a)
    if i == 1
        noti = 2    # the other traveler
    else
        noti = 1
    end
    if a[i] == a[noti]      # two agents choose the same money
        r = a[i]
    elseif a[i] < a[noti]   # traveler i gets less money than the other traveler
        r = a[i] + 2
    else                    # traveler i gets more money than the other traveler
        r = a[noti] - 2
    end
    return r    # true reward for agent i
end

# joint reward function for all agents in the game
function joint_reward(simpleGame::Travelers, a)
    return [reward(simpleGame, i, a) for i = 1:n_agents(simpleGame)]
end

# construct SimpleGame for Travelers Dilemma problem
function SimpleGame(simpleGame::Travelers)
    return SimpleGame(
        0.9,    # default discount factor for Travelers Dilemma is 0.9
        vec(collect(1:n_agents(simpleGame))),
        [ordered_actions(simpleGame, i) for i = 1:n_agents(simpleGame)],
        (a) -> joint_reward(simpleGame, a)
    )
end


# A best response of agent i to the policies of the other agents ??^(???i) is a policy ??^i 
# that maximizes the utility of the game ???? from the perspective of agent i.
# The formula for best response below is in page 495 of the book
#                       Ui(??^i, ??^(???i)) ??? Ui(??^(i???), ??^(???i))
function best_response(????::SimpleGame, ??, i)
    U(ai) = utility(????, joint(??, SimpleGamePolicy(ai), i), i)
    ai = argmax(U, ????.????[i])  # maximizes the utility 
    return SimpleGamePolicy(ai)
end

# A softmax response e to model how agent i will select their action with the precision parameter ??
# We often use softmax response to calculate how people will do their actions in the game
# precision parameter ?? is a probability in thinking of people to be more confident in their actions
# The formula for softmax response below is in page 497 of the book
#                       ??i(ai) ??? exp(??Ui(ai, ?????i)) 
function softmax_response(????::SimpleGame, ??, i, ??)
    ????i = ????.????[i]
    U(ai) = utility(????, joint(??, SimpleGamePolicy(ai), i), i)
    return SimpleGamePolicy(ai => exp(?? * U(ai)) for ai in ????i)
end

# experiment 1: calculate the reward of 2 computer agents
# the result will come close to Nash Equilibrium of the Travelers Dilemma: --> $2

# Model Iterated Best Response (page 503)
struct IteratedBestResponse
    k_max   # number of iterations
    ??       # initial policy
end

# constructor that takes as input a simple game and creates an initial policy that has each agent select actions uniformly at random
function IteratedBestResponse(????::SimpleGame, k_max)
    ?? = [SimpleGamePolicy(ai => 1.0 for ai in ????i) for ????i in ????.????]
    return IteratedBestResponse(k_max, ??)
end

# function to solve Iterated Best Response 
function solve(M::IteratedBestResponse, ????::SimpleGame)
    ?? = M.??
    for k = 1:M.k_max
        # use the best response to update the policy of each agent
        ?? = [best_response(????, ??, i) for i in ????.???]
    end
    return ??  # return policy, often close to Nash Equilibrium
end

# experiment 2: calculate the reward of 2 humen agents (behavioral game theory)
# the result we expect tend to be between $97 and $100 for human agents

# Model Hierarchical Softmax (page 504)
struct HierarchicalSoftmax
    ?? # precision parameter
    k # level
    ?? # initial policy
end

# By default, it starts with an initial joint policy that assigns uniform probability to all individual actions.
function HierarchicalSoftmax(????::SimpleGame, ??, k)
    ?? = [SimpleGamePolicy(ai => 1.0 for ai in ????i) for ????i in ????.????]
    return HierarchicalSoftmax(??, k, ??)
    # the result aims to model human agents, because people often do not play Nash equilibrium strategy
end

# function to solve Hierarchical Softmax 
function solve(M::HierarchicalSoftmax, ????)
    ?? = M.??
    for k = 1:M.k
        # use the softmax response to update the policy of each agent with the precision parameter ?? 
        ?? = [softmax_response(????, ??, i, M.??) for i in ????.???]
    end
    return ??
end


# EXAMPLE for our experiment

simpleGame = Travelers()  # simpleGame::Travelers
P = SimpleGame(simpleGame) # P is a SimpleGame instance according to simpleGame

# example of experiment 1: Iterated Best Response
# IBR = IteratedBestResponse(P, 1000) # IBR is used for finding policy for computer agents
# ??1 = solve(IBR, P)
# # print(??1)
# println("agent 1: ", ??1[1])
# println("agent 2: ", ??1[2])

# example of experiment 2: Hierarchical Softmax
# run the code below in REPL to see the visualization
HS = HierarchicalSoftmax(P, 0.5, 100) # HS is used for finding policy for human agents
??2 = solve(HS, P)

# visualize result with Plots
bar(collect(keys(??2[1].p)), collect(values(??2[1].p)), orientation = :vertical, legend = false)

# show the result to console
# for i = 2:100
#     print(i)
#     print(": ")
#     println(??2[1].p[i])
# end
