@event test_process() begin
    return true
end

@schedule nope test_process()
