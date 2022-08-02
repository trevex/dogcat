import useSWR from 'swr';
import { useGameContext } from "./GameProvider";

const scoreFetcher = (username: string, score?: number,) =>
    fetch('/api/scores', {
        method: score === undefined ? 'GET' : 'POST',
        cache: 'no-cache',
        headers: {
            'Content-Type': 'application/json'
        },
        body: score === undefined ? undefined : JSON.stringify({ score, username })
    }).then((res) => res.json());

type Score = {
    username: string,
    score: number,
    createdAt: Date,
    recent: boolean
};

type GameScoreboardProps = {
    score?: number
};

const GameScoreboard = ({ score: s }: GameScoreboardProps) => {
    const {
        playerName,
    } = useGameContext();

    const { data } = useSWR([playerName.current, s], scoreFetcher, {
        revalidateIfStale: true,
        revalidateOnFocus: false,
        revalidateOnReconnect: false
    });
    console.log(data);
    if (data === undefined) {
        return (
            <div className="absolute inset-0 flex justify-center items-center z-10">
                <p className="text-2xl font-bold">Loading...</p>
            </div>
        )
    }

    if (data.message !== undefined) { // Something went wrong!
        return (<p>{data.message}</p>
        )
    }

    const scores = (data as any[]).map<Score>((d) => ({
        username: d.username as string,
        score: d.score as number,
        createdAt: new Date(d.createdAt),
        recent: d.recent as boolean
    })).sort((a, b) => b.score - a.score);


    return (
        <div className="absolute inset-0 grid grid-flow-row auto-rows-max justify-center items-center z-10">
            <div className="pt-10 pb-4 text-center">
                <p className="text-2xl font-bold">Scoreboard</p>
            </div>
            <div className="overflow-hidden overflow-x-auto border-4 border-black rounded bg-gray-50">
                {scores.length === 0 ? (
                    <p className="px-4 py-4 font-bold">No scores available, yet...</p>
                ) : (
                    <table className="min-w-full text-sm divide-y-4 divide-gray-200">
                        <thead>
                            <tr className="bg-gray-50">
                                <th className="px-4 py-2 font-bold text-left text-gray-900 whitespace-nowrap">Name</th>
                                <th className="px-4 py-2 font-bold text-left text-gray-900 whitespace-nowrap">Date</th>
                                <th className="px-4 py-2 font-bold text-left text-gray-900 whitespace-nowrap">Score</th>
                            </tr>
                        </thead>

                        <tbody className="divide-y-2 divide-gray-100 bg-white">
                            {scores.map((s) => {
                                const key = "tr-" + s.createdAt.toString() + s.username + s.score;
                                return (
                                    <tr key={key} className={s.recent ? "text-red-600" : "text-gray-900"}>
                                        <td className="px-4 py-2 font-bold whitespace-nowrap">{s.username}</td>
                                        <td className="px-4 py-2 whitespace-nowrap">{s.createdAt.toLocaleString()}</td>
                                        <td className="px-4 py-2 font-bold whitespace-nowrap">{s.score}</td>
                                    </tr >
                                );
                            })}
                        </tbody>
                    </table>
                )}
            </div>

        </div>
    );
};

export default GameScoreboard;
