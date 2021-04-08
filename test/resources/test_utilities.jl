function unwrap(err)
    if !(:error in fieldnames(typeof(err)))
        return err
    end
    unwrap(err.error)
end

macro m_throw(mac)
    quote
        try
            eval($(esc(Expr(:inert, mac))))
        catch _e
            throw(unwrap(_e))
        end
    end
end
