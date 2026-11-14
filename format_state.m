function [state_string] = format_state(state, channel)
    state_string = "";
    if state == 1; state_string = "SLAVE"; elseif state == -1; state_string = "MASTER"; end
    state_string = state_string+channel;
end