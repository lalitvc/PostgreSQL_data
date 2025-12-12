#!/bin/bash

# Configuration
SQL_SERVER="localhost"
SQL_USER="your_username"
SQL_PASSWORD="your_password"
SQL_DATABASE="your_database"
RESULTS_DIR="./test_results"
REPORTS_DIR="./reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create directories if they don't exist
mkdir -p "$RESULTS_DIR" "$REPORTS_DIR"

# Function to run SQL script and generate result file
run_sql_script() {
    local sql_file="$1"
    local result_file="$2"
    
    echo "Running SQL script: $sql_file"
    
    # Run sqlcmd and capture output
    if sqlcmd -S "$SQL_SERVER" -U "$SQL_USER" -P "$SQL_PASSWORD" -d "$SQL_DATABASE" \
        -i "$sql_file" -W -h -1 -s "|" > "$result_file" 2>&1; then
        echo "✓ Successfully executed: $sql_file"
        return 0
    else
        echo "✗ Failed to execute: $sql_file"
        # Clean up empty or partial result file on failure
        rm -f "$result_file"
        return 1
    fi
}

# Function to compare result files
compare_results() {
    local new_result="$1"
    local expected_result="$2"
    local diff_file="$3"
    
    if [ ! -f "$expected_result" ]; then
        echo "No existing result file found for comparison: $expected_result"
        return 2
    fi
    
    # Compare files and generate diff
    if diff -u "$expected_result" "$new_result" > "$diff_file"; then
        echo "✓ Results match: $new_result"
        return 0
    else
        echo "✗ Results differ: $new_result"
        return 1
    fi
}

# Function to generate status report
generate_report() {
    local report_file="$1"
    local status_summary=("${!2}")
    
    {
        echo "SQL Test Results Report"
        echo "========================"
        echo "Generated: $(date)"
        echo "Timestamp: $TIMESTAMP"
        echo ""
        echo "Summary:"
        echo "--------"
        
        total_tests=${#status_summary[@]}
        passed=0
        failed=0
        new_files=0
        
        for status in "${status_summary[@]}"; do
            case $status in
                "PASSED") ((passed++)) ;;
                "FAILED") ((failed++)) ;;
                "NEW") ((new_files++)) ;;
            esac
        done
        
        echo "Total Tests: $total_tests"
        echo "Passed: $passed"
        echo "Failed: $failed"
        echo "New Files: $new_files"
        echo ""
        
        if [ $failed -gt 0 ]; then
            echo "❌ Some tests failed!"
        elif [ $total_tests -eq $passed ]; then
            echo "✅ All tests passed!"
        else
            echo "⚠️  All existing tests passed, but new files were created"
        fi
        
        echo ""
        echo "Detailed Results:"
        echo "-----------------"
        
        for i in "${!status_summary[@]}"; do
            echo "Test $((i+1)): ${status_summary[$i]}"
        done
        
    } > "$report_file"
    
    echo "Report generated: $report_file"
}

# Main execution
main() {
    local sql_files=(*.sql)
    local status_summary=()
    local report_file="$REPORTS_DIR/report_$TIMESTAMP.txt"
    local detailed_report_file="$REPORTS_DIR/detailed_report_$TIMESTAMP.txt"
    
    if [ ${#sql_files[@]} -eq 0 ]; then
        echo "No SQL files found in current directory!"
        exit 1
    fi
    
    {
        echo "Starting SQL test execution..."
        echo "Timestamp: $TIMESTAMP"
        echo "SQL Server: $SQL_SERVER"
        echo "Database: $SQL_DATABASE"
        echo ""
        
        for sql_file in "${sql_files[@]}"; do
            if [ -f "$sql_file" ]; then
                base_name=$(basename "$sql_file" .sql)
                new_result="$RESULTS_DIR/${base_name}_new.result"
                expected_result="$RESULTS_DIR/${base_name}.result"
                diff_file="$RESULTS_DIR/${base_name}.diff"
                
                echo "Processing: $sql_file"
                echo "----------------------------------------"
                
                # Run SQL script
                if run_sql_script "$sql_file" "$new_result"; then
                    # Compare with existing result
                    compare_results "$new_result" "$expected_result" "$diff_file"
                    compare_exit_code=$?
                    
                    case $compare_exit_code in
                        0)
                            echo "Status: PASSED"
                            status_summary+=("PASSED")
                            # Clean up temporary new result file since it matches
                            rm -f "$new_result" "$diff_file"
                            ;;
                        1)
                            echo "Status: FAILED"
                            echo "Diff file: $diff_file"
                            status_summary+=("FAILED")
                            ;;
                        2)
                            echo "Status: NEW (No existing result file)"
                            # Rename new result to expected result for future comparisons
                            mv "$new_result" "$expected_result"
                            status_summary+=("NEW")
                            ;;
                    esac
                else
                    echo "Status: ERROR (SQL execution failed)"
                    status_summary+=("FAILED")
                fi
                
                echo ""
            fi
        done
        
        # Generate summary report
        generate_report "$report_file" status_summary[@]
        
        echo "Execution completed!"
        echo "Summary report: $report_file"
        
    } | tee "$detailed_report_file"
    
    # Display final summary
    echo ""
    echo "=== FINAL SUMMARY ==="
    cat "$report_file" | grep -E "(Total Tests|Passed|Failed|New Files|❌|✅|⚠️)"
}

# Handle script termination
cleanup() {
    echo "Script interrupted. Cleaning up..."
    # Remove any temporary new result files
    find "$RESULTS_DIR" -name "*_new.result" -delete
    exit 1
}

trap cleanup SIGINT SIGTERM

# Check if sqlcmd is available
if ! command -v sqlcmd &> /dev/null; then
    echo "Error: sqlcmd is not installed or not in PATH"
    exit 1
fi

# Run main function
main "$@"

Key Achievements:
Successfully took over and led an ongoing database testing project, rapidly understanding requirements and collaborating with developers to deliver on schedule.

Expertly managed the simultaneous testing of multiple projects and features, coordinating with various stakeholders and delivering all work in a timely manner.

Produced detailed and actionable test reports to ensure clarity and quality.

Enhanced team capability by conducting knowledge-sharing sessions on database testing best practices.

Contributed directly to feature development by providing solutions informed by deep database development and testing experience.

Fostered team growth by proactively supporting and mentoring colleagues.

Summary Statement:
A results-driven professional who ensured the seamless delivery of critical database projects through effective coordination, multi-project management, and detailed reporting, while actively upskilling the team and contributing to product development.
