import subprocess

# Define the library paths for each corner
LIBS = {
    "slow": "/path/to/slow.lib",
    "typical": "/path/to/typical.lib",
    "fast": "/path/to/fast.lib",
}

# Define the corners for STA with their corresponding libraries
CORNERS = {
    "SS_0.9V_125C": LIBS["slow"],
    "TT_1.1V_25C": LIBS["typical"],
    "FF_1.25V_-40C": LIBS["fast"],
    "TT_1.1V_100C": LIBS["typical"],
}

MODES = {
    "FUNC" : CORNERS["SS_0.9V_125C"],
    "FUNC" : CORNER["FF_1.25V_-40C"],
    "TEST" : CORNER["FF_1.25V_-40c"],
    "BIST" : CORNER["SS_0.9C_125C"]
        }
# Path to the STA script
STA_SCRIPT = "/path/to/sta_script.tcl"

def task_sta():
    """
    A single task to run openSTA for all corners in separate terminals.
    """
    def run_in_terminal(corner, lib_path):
        """Helper function to spawn a terminal."""
        subprocess.Popen(
            [
                "gnome-terminal",
                "--",
                "bash",
                "-c",
                f"opensta -f {STA_SCRIPT} -set lib {lib_path} -set corner {corner}; exec bash"
            ]
        )
        return True  # Ensure the task reports success

    return {
        'actions': [
            (run_in_terminal, [corner, lib_path]) for corner, lib_path in CORNERS.items()
        ],
        'verbosity': 2,
    }

