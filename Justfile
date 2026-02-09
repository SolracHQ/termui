# List all available examples
list:
    @echo "Available examples:"
    @ls examples/*.nim | sed 's/examples\//  - /' | sed 's/\.nim$//'

# Run a specific example by name (without .nim extension)
run EXAMPLE:
    nim r examples/{{EXAMPLE}}.nim

# Run all examples one by one
run-all:
    @for file in examples/*.nim; do \
        echo "Running $$file..."; \
        nim r $$file; \
        echo ""; \
    done

# Compile an example without running it
compile EXAMPLE:
    nim c examples/{{EXAMPLE}}.nim

# Clean compiled artifacts
clean:
    rm -f examples/colombian_flag examples/simple_label
    rm -rf examples/nimcache

# Show help
help:
    @echo "TermUI - Available commands:"
    @echo ""
    @echo "  just list           - List all available examples"
    @echo "  just run EXAMPLE    - Run a specific example (e.g., just run colombian_flag)"
    @echo "  just run-all        - Run all examples sequentially"
    @echo "  just compile EXAMPLE - Compile without running"
    @echo "  just clean          - Remove compiled artifacts"
    @echo "  just help           - Show this help message"
