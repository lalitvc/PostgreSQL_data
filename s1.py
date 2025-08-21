#!/usr/bin/env python3
"""
SQL Script Runner and Comparator
Runs SQL scripts using sqlcmd, compares results with expected results,
and reports failures.
"""

import os
import sys
import subprocess
import json
import argparse
from pathlib import Path
from typing import List
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('sql_runner.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class TestResult:
    def __init__(self, script_name: str, success: bool, exit_code: int,
                 output_file: str, expected_file: str, differences: List[str],
                 execution_time: float):
        self.script_name = script_name
        self.success = success
        self.exit_code = exit_code
        self.output_file = output_file
        self.expected_file = expected_file
        self.differences = differences
        self.execution_time = execution_time

class SQLScriptRunner:
    def __init__(self, sqlcmd_path: str = "sqlcmd"):
        self.sqlcmd_path = sqlcmd_path
        self.base_dir = Path("sql_test_results")
        self.scripts_dir = self.base_dir / "scripts"
        self.results_dir = self.base_dir / "results"
        self.expected_dir = self.base_dir / "expected"
        self.failed_dir = self.base_dir / "failed"
        
        # Create directories
        for directory in [self.scripts_dir, self.results_dir, 
                         self.expected_dir, self.failed_dir]:
            directory.mkdir(parents=True, exist_ok=True)
    
    def get_sql_scripts(self) -> List[Path]:
        """Get all SQL scripts from the scripts directory"""
        sql_files = list(self.scripts_dir.glob("*.sql"))
        logger.info(f"Found {len(sql_files)} SQL scripts in {self.scripts_dir}")
        return sql_files
    
    def run_sql_script(self, sql_file: Path, server: str, database: str, 
                      username: str, password: str) -> TestResult:
        """Run a single SQL script using sqlcmd"""
        result_file = self.results_dir / f"{sql_file.stem}_result.txt"
        expected_file = self.expected_dir / f"{sql_file.stem}_expected.txt"
        
        start_time = datetime.now()
        
        # Build sqlcmd command
        cmd = [
            self.sqlcmd_path,
            "-S", server,
            "-d", database,
            "-U", username,
            "-P", password,
            "-i", str(sql_file),
            "-o", str(result_file),
            "-s", "|",  # Column separator
            "-W",  # Remove trailing spaces
            "-b"  # Exit on error
        ]
        
        try:
            # Execute sqlcmd
            logger.info(f"Running script: {sql_file.name}")
            process = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=300  # 5 minute timeout per script
            )
            
            execution_time = (datetime.now() - start_time).total_seconds()
            
            # Check if result file was created
            if not result_file.exists():
                logger.error(f"No output file generated for {sql_file.name}")
                return TestResult(
                    script_name=sql_file.name,
                    success=False,
                    exit_code=process.returncode,
                    output_file=str(result_file),
                    expected_file=str(expected_file),
                    differences=["No output file generated"],
                    execution_time=execution_time
                )
            
            # Compare with expected result if exists
            differences = []
            if expected_file.exists():
                logger.info(f"Comparing results for {sql_file.name}")
                differences = self.compare_results(result_file, expected_file)
            else:
                logger.warning(f"No expected result file found for {sql_file.name}")
            
            success = process.returncode == 0 and not differences
            
            if success:
                logger.info(f"PASSED: {sql_file.name} ({execution_time:.2f}s)")
            else:
                logger.error(f"FAILED: {sql_file.name} (Exit code: {process.returncode})")
                for diff in differences:
                    logger.error(f"  Difference: {diff}")
            
            return TestResult(
                script_name=sql_file.name,
                success=success,
                exit_code=process.returncode,
                output_file=str(result_file),
                expected_file=str(expected_file),
                differences=differences,
                execution_time=execution_time
            )
            
        except subprocess.TimeoutExpired:
            execution_time = (datetime.now() - start_time).total_seconds()
            logger.error(f"Timeout running {sql_file.name}")
            return TestResult(
                script_name=sql_file.name,
                success=False,
                exit_code=-1,
                output_file=str(result_file),
                expected_file=str(expected_file),
                differences=["Execution timeout"],
                execution_time=execution_time
            )
        except Exception as e:
            execution_time = (datetime.now() - start_time).total_seconds()
            logger.error(f"Error running {sql_file.name}: {e}")
            return TestResult(
                script_name=sql_file.name,
                success=False,
                exit_code=-1,
                output_file=str(result_file),
                expected_file=str(expected_file),
                differences=[f"Execution error: {str(e)}"],
                execution_time=execution_time
            )
    
    def compare_results(self, actual_file: Path, expected_file: Path) -> List[str]:
        """Compare actual results with expected results"""
        differences = []
        
        try:
            with open(actual_file, 'r', encoding='utf-8', errors='ignore') as f_actual:
                actual_lines = [line.strip() for line in f_actual if line.strip()]
            
            with open(expected_file, 'r', encoding='utf-8', errors='ignore') as f_expected:
                expected_lines = [line.strip() for line in f_expected if line.strip()]
            
            # Compare line by line
            min_lines = min(len(actual_lines), len(expected_lines))
            for i in range(min_lines):
                if actual_lines[i] != expected_lines[i]:
                    differences.append(f"Line {i+1}: Expected '{expected_lines[i]}', Got '{actual_lines[i]}'")
            
            # Check for different number of lines
            if len(actual_lines) != len(expected_lines):
                differences.append(f"Different number of lines: Expected {len(expected_lines)}, Got {len(actual_lines)}")
                
        except Exception as e:
            differences.append(f"Error comparing files: {e}")
        
        return differences
    
    def save_failed_result(self, result: TestResult):
        """Save details of failed test for reporting"""
        failed_file = self.failed_dir / f"{result.script_name}_failure.json"
        
        failure_data = {
            "script_name": result.script_name,
            "timestamp": datetime.now().isoformat(),
            "success": result.success,
            "exit_code": result.exit_code,
            "execution_time": result.execution_time,
            "differences": result.differences,
            "output_file": result.output_file,
            "expected_file": result.expected_file if os.path.exists(result.expected_file) else "Not found"
        }
        
        with open(failed_file, 'w') as f:
            json.dump(failure_data, f, indent=2)
        
        logger.info(f"Saved failure details to {failed_file}")
    
    def generate_report(self, results: List[TestResult]) -> Dict:
        """Generate comprehensive test report"""
        total_scripts = len(results)
        passed_scripts = sum(1 for r in results if r.success)
        failed_scripts = total_scripts - passed_scripts
        
        report = {
            "timestamp": datetime.now().isoformat(),
            "total_scripts": total_scripts,
            "passed_scripts": passed_scripts,
            "failed_scripts": failed_scripts,
            "success_rate": (passed_scripts / total_scripts * 100) if total_scripts > 0 else 0,
            "execution_details": []
        }
        
        for result in results:
            report["execution_details"].append({
                "script_name": result.script_name,
                "success": result.success,
                "exit_code": result.exit_code,
                "execution_time": round(result.execution_time, 2),
                "has_expected_file": os.path.exists(result.expected_file),
                "differences_count": len(result.differences)
            })
        
        # Save report to file
        report_file = self.base_dir / "test_report.json"
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        logger.info(f"Generated test report: {report_file}")
        return report
    
    def run_tests(self, server: str, database: str, username: str, password: str) -> List[TestResult]:
        """Main method to run all tests sequentially"""
        # Get SQL scripts
        sql_files = self.get_sql_scripts()
        
        if not sql_files:
            logger.error("No SQL scripts found in scripts directory")
            return []
        
        logger.info(f"Running {len(sql_files)} SQL scripts sequentially")
        
        results = []
        failed_count = 0
        
        # Run scripts sequentially
        for sql_file in sql_files:
            result = self.run_sql_script(sql_file, server, database, username, password)
            results.append(result)
            
            if not result.success:
                failed_count += 1
                self.save_failed_result(result)
        
        # Generate final report
        report = self.generate_report(results)
        
        logger.info(f"\n=== TEST SUMMARY ===")
        logger.info(f"Total scripts: {report['total_scripts']}")
        logger.info(f"Passed: {report['passed_scripts']}")
        logger.info(f"Failed: {report['failed_scripts']}")
        logger.info(f"Success rate: {report['success_rate']:.1f}%")
        
        if report['failed_scripts'] > 0:
            logger.error("Some tests failed. Check failed/ directory for details.")
        
        return results

def main():
    parser = argparse.ArgumentParser(description="Run SQL scripts and compare results")
    parser.add_argument("--server", required=True, help="SQL Server instance")
    parser.add_argument("--database", required=True, help="Database name")
    parser.add_argument("--username", required=True, help="SQL Server username")
    parser.add_argument("--password", required=True, help="SQL Server password")
    parser.add_argument("--sqlcmd", default="sqlcmd", help="Path to sqlcmd executable")
    
    args = parser.parse_args()
    
    # Create runner instance
    runner = SQLScriptRunner(sqlcmd_path=args.sqlcmd)
    
    # Run tests
    failed_tests = runner.run_tests(
        server=args.server,
        database=args.database,
        username=args.username,
        password=args.password
    )
    
    # Exit with error code if any tests failed
    if failed_tests:
        sys.exit(1)
    else:
        sys.exit(0)

if __name__ == "__main__":
    main()